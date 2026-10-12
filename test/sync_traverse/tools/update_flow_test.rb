require "test_helper"

module SyncTraverse
  module Tools
    class UpdateFlowTest < SyncTraverse::TestCase
      def test_adds_transitions_to_draft_and_creates_referenced_actions
        response = UpdateFlow.call(
          flow_name: "orders/purchase",
          add_transitions: [
            { source: "validate_order", target: "charge_payment", source_result: "valid" },
            { source: "validate_order", target: nil, source_result: "invalid" },
            { source: "charge_payment", target: nil, source_result: "paid" }
          ],
          server_context: {}
        )

        assert_equal "Success", response.content.first[:text]
        assert_equal(
          {
            "validate_order" => { "valid" => "charge_payment", "invalid" => nil },
            "charge_payment" => { "paid" => nil }
          },
          JSON.parse(File.read(flow_draft_path("orders/purchase")))
        )
        refute_path_exists flow_stable_path("orders/purchase")
      end

      def test_first_update_copies_stable_flow_to_draft_and_leaves_it_untouched
        write_flow_stable("orders/purchase", { "a" => { "ok" => "b" }, "b" => { "done" => nil } })

        response = UpdateFlow.call(
          flow_name: "orders/purchase",
          add_transitions: [{ source: "b", target: "c", source_result: "other" }],
          server_context: {}
        )

        refute_predicate response, :error?
        assert_equal(
          { "a" => { "ok" => "b" }, "b" => { "done" => nil, "other" => "c" }, "c" => {} },
          JSON.parse(File.read(flow_draft_path("orders/purchase")))
        )
        assert_equal({ "a" => { "ok" => "b" }, "b" => { "done" => nil } }, JSON.parse(File.read(flow_stable_path("orders/purchase"))))
      end

      def test_updates_existing_draft_instead_of_stable_flow
        write_flow_stable("orders/purchase", { "a" => { "ok" => nil } })
        write_flow_draft("orders/purchase", { "a" => { "ok" => "b" }, "b" => {} })

        UpdateFlow.call(
          flow_name: "orders/purchase",
          add_transitions: [{ source: "b", target: nil, source_result: "done" }],
          server_context: {}
        )

        assert_equal(
          { "a" => { "ok" => "b" }, "b" => { "done" => nil } },
          JSON.parse(File.read(flow_draft_path("orders/purchase")))
        )
      end

      def test_rejects_update_in_approved_phase
        write_flow_approved("orders/purchase", { "a" => { "ok" => nil } })

        response = UpdateFlow.call(
          flow_name: "orders/purchase",
          add_transitions: [{ source: "a", target: nil, source_result: "other" }],
          server_context: {}
        )

        assert_predicate response, :error?
        assert_equal(
          "Flow orders/purchase is approved; call reopen_draft to change the graph",
          response.content.first[:text]
        )
        assert_equal({ "a" => { "ok" => nil } }, JSON.parse(File.read(flow_approved_path("orders/purchase"))))
      end

      def test_removes_transitions_before_adding
        write_flow_stable("orders/purchase", { "a" => { "old" => "b" }, "b" => {} })

        response = UpdateFlow.call(
          flow_name: "orders/purchase",
          remove_transitions: [{ source: "a", target: "b", source_result: "old" }],
          add_transitions: [{ source: "a", target: nil, source_result: "old" }],
          server_context: {}
        )

        refute_predicate response, :error?
        assert_equal({ "a" => { "old" => nil } }, JSON.parse(File.read(flow_draft_path("orders/purchase"))))
      end

      def test_keeps_empty_draft_when_no_actions_left_in_existing_flow
        write_flow_stable("orders/purchase", { "a" => { "done" => nil } })

        response = UpdateFlow.call(
          flow_name: "orders/purchase",
          remove_transitions: [{ source: "a", target: nil, source_result: "done" }],
          server_context: {}
        )

        assert_equal "Success. Draft has no actions left; promoting it deletes the flow.", response.content.first[:text]
        assert_equal({}, JSON.parse(File.read(flow_draft_path("orders/purchase"))))
        assert_path_exists flow_stable_path("orders/purchase")
      end

      def test_creates_no_draft_for_new_flow_without_actions
        response = UpdateFlow.call(flow_name: "orders/purchase", server_context: {})

        refute_predicate response, :error?
        assert_equal "Success. Flow has no actions; there is nothing to draft.", response.content.first[:text]
        refute File.directory?(File.join(flows_dir, "orders"))
      end

      def test_discards_draft_when_new_flow_has_no_actions_left
        write_flow_draft("orders/purchase", { "a" => { "done" => nil } })
        File.write(flow_draft_diagram_path("orders/purchase"), "flowchart TD")

        response = UpdateFlow.call(
          flow_name: "orders/purchase",
          remove_transitions: [{ source: "a", target: nil, source_result: "done" }],
          server_context: {}
        )

        refute_predicate response, :error?
        refute File.directory?(File.join(flows_dir, "orders"))
      end

      def test_rejects_cycle_without_saving
        response = UpdateFlow.call(
          flow_name: "orders/purchase",
          add_transitions: [
            { source: "a", target: "b", source_result: "ok" },
            { source: "b", target: "a", source_result: "back" }
          ],
          server_context: {}
        )

        assert_predicate response, :error?
        assert_equal(
          "Flow must be acyclic\nFlow must have exactly one source action, found: none",
          response.content.first[:text]
        )
        refute_path_exists flow_draft_path("orders/purchase")
      end

      def test_allows_multiple_results_leading_to_same_action
        response = UpdateFlow.call(
          flow_name: "orders/purchase",
          add_transitions: [
            { source: "a", target: "b", source_result: "x" },
            { source: "a", target: "b", source_result: "y" }
          ],
          server_context: {}
        )

        refute_predicate response, :error?
      end

      def test_allows_multiple_results_leading_to_null
        response = UpdateFlow.call(
          flow_name: "orders/purchase",
          add_transitions: [
            { source: "persist_user", target: nil, source_result: "created" },
            { source: "persist_user", target: nil, source_result: "invalid" }
          ],
          server_context: {}
        )

        refute_predicate response, :error?
        assert_equal({ "created" => nil, "invalid" => nil }, JSON.parse(File.read(flow_draft_path("orders/purchase")))["persist_user"])
      end

      def test_allows_same_target_from_different_actions
        response = UpdateFlow.call(
          flow_name: "orders/purchase",
          add_transitions: [
            { source: "a", target: "c", source_result: "x" },
            { source: "a", target: "b", source_result: "y" },
            { source: "b", target: "c", source_result: "z" }
          ],
          server_context: {}
        )

        refute_predicate response, :error?
      end

      def test_rejects_conflicting_result_target
        write_flow_stable("orders/purchase", { "a" => { "ok" => "b" }, "b" => {} })

        response = UpdateFlow.call(
          flow_name: "orders/purchase",
          add_transitions: [{ source: "a", target: "c", source_result: "ok" }],
          server_context: {}
        )

        assert_predicate response, :error?
        assert_equal(
          "Result 'ok' of action 'a' already targets 'b'; remove that transition first",
          response.content.first[:text]
        )
      end

      def test_rejects_invalid_action_name
        response = UpdateFlow.call(
          flow_name: "orders/purchase",
          add_transitions: [{ source: "../escape", target: nil, source_result: "ok" }],
          server_context: {}
        )

        assert_predicate response, :error?
        assert_equal "Invalid name(s): ../escape", response.content.first[:text]
      end
    end
  end
end
