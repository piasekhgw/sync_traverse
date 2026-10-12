require "test_helper"

module SyncTraverse
  module Tools
    class ApproveDraftsTest < SyncTraverse::TestCase
      def test_renames_draft_to_approved_flow
        write_flow_draft("orders/purchase", { "a" => { "ok" => "b" }, "b" => {} })

        response = ApproveDrafts.call(flow_names: ["orders/purchase"], server_context: {})

        refute_predicate response, :error?
        assert_path_exists flow_approved_path("orders/purchase")
        refute_path_exists flow_draft_path("orders/purchase")
      end

      def test_renames_draft_diagram_to_approved_diagram
        write_flow_draft("orders/purchase", { "a" => { "ok" => nil } })
        File.write(flow_draft_diagram_path("orders/purchase"), "flowchart TD")

        ApproveDrafts.call(flow_names: ["orders/purchase"], server_context: {})

        assert_equal "flowchart TD", File.read(flow_approved_diagram_path("orders/purchase"))
        refute_path_exists flow_draft_diagram_path("orders/purchase")
      end

      def test_does_not_change_stable_flow
        write_flow_stable("orders/purchase", { "a" => { "ok" => nil } })
        write_flow_draft("orders/purchase", { "a" => { "ok" => "b" }, "b" => {} })

        ApproveDrafts.call(flow_names: ["orders/purchase"], server_context: {})

        assert_equal({ "a" => { "ok" => nil } }, JSON.parse(File.read(flow_stable_path("orders/purchase"))))
      end

      def test_blocks_update_flow_afterwards
        write_flow_draft("orders/purchase", { "a" => { "ok" => nil } })
        ApproveDrafts.call(flow_names: ["orders/purchase"], server_context: {})

        response = UpdateFlow.call(
          flow_name: "orders/purchase",
          add_transitions: [{ source: "a", target: nil, source_result: "other" }],
          server_context: {}
        )

        assert_predicate response, :error?
        refute_path_exists flow_draft_path("orders/purchase")
      end

      def test_rejects_flow_without_draft
        write_flow_stable("orders/purchase", { "a" => { "ok" => nil } })

        response = ApproveDrafts.call(flow_names: ["orders/purchase"], server_context: {})

        assert_predicate response, :error?
        assert_equal "No draft for flow orders/purchase; call update_flow first", response.content.first[:text]
      end

      def test_rejects_invalid_draft
        write_flow_draft("orders/purchase", { "a" => { "ok" => "b" }, "b" => { "back" => "a" } })

        response = ApproveDrafts.call(flow_names: ["orders/purchase"], server_context: {})

        assert_predicate response, :error?
        refute_path_exists flow_approved_path("orders/purchase")
      end

      def test_rejects_flow_already_approved
        write_flow_approved("orders/purchase", { "a" => { "ok" => nil } })

        response = ApproveDrafts.call(flow_names: ["orders/purchase"], server_context: {})

        assert_predicate response, :error?
        assert_equal "Flow orders/purchase is already approved", response.content.first[:text]
      end

      def test_rejects_invalid_flow_name
        response = ApproveDrafts.call(flow_names: ["../escape"], server_context: {})

        assert_predicate response, :error?
        assert_equal "Invalid name(s): ../escape", response.content.first[:text]
      end

      def test_rejects_draft_changing_results_of_action_used_by_other_flow
        write_flow_stable("billing/invoice", { "charge" => { "paid" => nil, "declined" => nil } })
        write_flow_draft("orders/purchase", { "charge" => { "paid" => nil, "declined" => nil, "error" => nil } })

        response = ApproveDrafts.call(flow_names: ["orders/purchase"], server_context: {})

        assert_equal(
          "Action charge has different results in flows billing/invoice (declined, paid), " \
          "orders/purchase (declined, error, paid); keep them identical or use a new action",
          response.content.first[:text]
        )
        assert_path_exists flow_draft_path("orders/purchase")
      end

      def test_allows_identical_results_in_other_flow_regardless_of_order
        write_flow_stable("billing/invoice", { "charge" => { "paid" => nil, "declined" => "notify" }, "notify" => { "sent" => nil } })
        write_flow_draft("orders/purchase", { "charge" => { "declined" => nil, "paid" => nil } })

        response = ApproveDrafts.call(flow_names: ["orders/purchase"], server_context: {})

        refute_predicate response, :error?
      end

      def test_ignores_drafts_and_approved_versions_of_flows_outside_the_call
        write_flow_draft("billing/invoice", { "charge" => { "paid" => nil } })
        write_flow_approved("billing/refund", { "charge" => { "refunded" => nil } })
        write_flow_draft("orders/purchase", { "charge" => { "paid" => nil, "declined" => nil } })

        response = ApproveDrafts.call(flow_names: ["orders/purchase"], server_context: {})

        refute_predicate response, :error?
      end

      def test_allows_changing_results_compared_to_own_stable_flow
        write_flow_stable("orders/purchase", { "charge" => { "paid" => nil } })
        write_flow_draft("orders/purchase", { "charge" => { "paid" => nil, "declined" => nil } })

        response = ApproveDrafts.call(flow_names: ["orders/purchase"], server_context: {})

        refute_predicate response, :error?
      end

      def test_approves_flows_changing_a_shared_action_together
        write_flow_stable("billing/invoice", { "charge" => { "paid" => nil } })
        write_flow_stable("orders/purchase", { "charge" => { "paid" => nil } })
        write_flow_draft("billing/invoice", { "charge" => { "paid" => nil, "declined" => nil } })
        write_flow_draft("orders/purchase", { "charge" => { "paid" => nil, "declined" => nil } })

        response = ApproveDrafts.call(flow_names: ["billing/invoice", "orders/purchase"], server_context: {})

        refute_predicate response, :error?
        assert_path_exists flow_approved_path("billing/invoice")
        assert_path_exists flow_approved_path("orders/purchase")
      end

      def test_rejects_different_results_between_drafts_of_the_call
        write_flow_draft("billing/invoice", { "charge" => { "paid" => nil } })
        write_flow_draft("orders/purchase", { "charge" => { "declined" => nil } })

        response = ApproveDrafts.call(flow_names: ["billing/invoice", "orders/purchase"], server_context: {})

        assert_predicate response, :error?
        refute_path_exists flow_approved_path("billing/invoice")
      end

      def test_approves_nothing_when_one_flow_of_the_call_has_no_draft
        write_flow_draft("billing/invoice", { "charge" => { "paid" => nil } })
        write_flow_stable("orders/purchase", { "charge" => { "paid" => nil } })

        response = ApproveDrafts.call(flow_names: ["billing/invoice", "orders/purchase"], server_context: {})

        assert_predicate response, :error?
        refute_path_exists flow_approved_path("billing/invoice")
      end
    end
  end
end
