require "test_helper"

module SyncTraverse
  module Tools
    class PromoteFlowsTest < SyncTraverse::TestCase
      def test_replaces_stable_flow_with_approved_flow
        write_flow_stable("orders/purchase", { "a" => { "ok" => nil } })
        write_approved("orders/purchase", { "a" => { "ok" => "b" }, "b" => {} })

        response = PromoteFlows.call(flow_names: ["orders/purchase"], server_context: {})

        refute_predicate response, :error?
        assert_equal({ "a" => { "ok" => "b" }, "b" => {} }, JSON.parse(File.read(flow_stable_path("orders/purchase"))))
      end

      def test_leaves_only_stable_flow
        write_approved("orders/purchase", { "a" => { "ok" => nil } })

        PromoteFlows.call(flow_names: ["orders/purchase"], server_context: {})

        refute_path_exists flow_approved_path("orders/purchase")
        refute_path_exists flow_draft_path("orders/purchase")
      end

      def test_replaces_diagram_with_approved_diagram
        write_approved("orders/purchase", { "a" => { "ok" => nil } })
        File.write(flow_stable_diagram_path("orders/purchase"), "old")
        File.write(flow_approved_diagram_path("orders/purchase"), "new")

        PromoteFlows.call(flow_names: ["orders/purchase"], server_context: {})

        assert_equal "new", File.read(flow_stable_diagram_path("orders/purchase"))
        refute_path_exists flow_approved_diagram_path("orders/purchase")
      end

      def test_makes_flow_stable_phase
        write_approved("orders/purchase", { "a" => { "ok" => nil } })
        PromoteFlows.call(flow_names: ["orders/purchase"], server_context: {})

        response = GetFlow.call(flow_name: "orders/purchase", server_context: {})

        assert_equal "stable", JSON.parse(response.content.first[:text])["phase"]
      end

      def test_deletes_flow_when_approved_flow_has_no_actions
        write_flow_stable("orders/purchase", { "a" => { "ok" => nil } })
        write_flow_approved("orders/purchase", {})

        response = PromoteFlows.call(flow_names: ["orders/purchase"], server_context: {})

        refute_predicate response, :error?
        refute File.directory?(File.join(flows_dir, "orders"))
      end

      def test_deletes_flow_tests_when_approved_flow_has_no_actions
        write_flow_stable("orders/purchase", { "a" => { "ok" => nil } })
        write_flow_approved("orders/purchase", {})
        write_flow_test("orders/purchase", "'test'")

        PromoteFlows.call(flow_names: ["orders/purchase"], server_context: {})

        refute File.directory?(File.join(flow_tests_dir, "orders"))
      end

      def test_promotes_nothing_when_flow_test_fails
        write_approved("orders/purchase", { "charge" => { "paid" => nil } })
        write_flow_test("orders/purchase", failing_test)

        response = PromoteFlows.call(flow_names: ["orders/purchase"], server_context: {})

        assert_match(/\ATests failed; nothing was promoted\.\n.*boom/m, response.content.first[:text])
        assert_path_exists flow_approved_path("orders/purchase")
      end

      def test_rejects_draft_that_was_not_approved
        write_flow_stable("orders/purchase", { "a" => { "ok" => nil } })
        write_flow_draft("orders/purchase", { "a" => { "ok" => "b" }, "b" => {} })

        response = PromoteFlows.call(flow_names: ["orders/purchase"], server_context: {})

        assert_predicate response, :error?
        assert_equal({ "a" => { "ok" => nil } }, JSON.parse(File.read(flow_stable_path("orders/purchase"))))
      end

      def test_promotes_several_flows
        write_approved("billing/invoice", { "charge" => { "paid" => nil } })
        write_approved("orders/purchase", { "charge" => { "paid" => nil } })

        response = PromoteFlows.call(flow_names: ["billing/invoice", "orders/purchase"], server_context: {})

        refute_predicate response, :error?
        assert_path_exists flow_stable_path("billing/invoice")
        assert_path_exists flow_stable_path("orders/purchase")
      end

      def test_promotes_nothing_when_one_flow_of_the_call_is_not_approved
        write_flow_approved("billing/invoice", { "charge" => { "paid" => nil } })
        write_flow_draft("orders/purchase", { "charge" => { "paid" => nil } })

        response = PromoteFlows.call(flow_names: ["billing/invoice", "orders/purchase"], server_context: {})

        assert_equal "Flow orders/purchase is not approved; call approve_drafts first", response.content.first[:text]
        refute_path_exists flow_stable_path("billing/invoice")
      end

      def test_rejects_promotion_without_another_flow_approved_together
        write_flow_stable("billing/invoice", { "charge" => { "paid" => nil } })
        write_flow_approved("billing/invoice", { "charge" => { "paid" => nil, "declined" => nil } })
        write_flow_approved("orders/purchase", { "charge" => { "paid" => nil, "declined" => nil } })

        response = PromoteFlows.call(flow_names: ["orders/purchase"], server_context: {})

        assert_equal(
          "Action charge has different results in flows billing/invoice (paid), " \
          "orders/purchase (declined, paid); keep them identical or use a new action",
          response.content.first[:text]
        )
        assert_path_exists flow_approved_path("orders/purchase")
      end

      def test_does_not_compare_with_own_stable_flow
        write_flow_stable("orders/purchase", { "charge" => { "paid" => nil } })
        write_approved("orders/purchase", { "charge" => { "paid" => nil, "declined" => nil } })

        response = PromoteFlows.call(flow_names: ["orders/purchase"], server_context: {})

        refute_predicate response, :error?
      end

      def test_deleted_flow_no_longer_counts_as_user_of_its_actions
        write_flow_stable("billing/invoice", { "charge" => { "paid" => nil } })
        write_flow_approved("billing/invoice", {})
        write_approved("orders/purchase", { "charge" => { "declined" => nil } })

        response = PromoteFlows.call(flow_names: ["billing/invoice", "orders/purchase"], server_context: {})

        refute_predicate response, :error?
      end

      def test_promotes_nothing_when_results_check_fails
        write_flow_stable("orders/purchase", { "charge" => { "paid" => nil } })
        write_flow_approved("orders/purchase", { "charge" => { "paid" => nil, "declined" => nil } })
        write_action_with_results("charge", %w[paid])

        response = PromoteFlows.call(flow_names: ["orders/purchase"], server_context: {})

        assert_predicate response, :error?
        assert_match(/\ATests failed; nothing was promoted\.\n.*not declared in .*RESULTS/m, response.content.first[:text])
        assert_path_exists flow_approved_path("orders/purchase")
      end

      def test_promotes_nothing_when_action_test_fails
        write_approved("billing/invoice", { "charge" => { "paid" => nil } })
        write_approved("orders/purchase", { "charge" => { "paid" => nil } })
        write_action_test("charge", failing_test)

        response = PromoteFlows.call(flow_names: ["billing/invoice", "orders/purchase"], server_context: {})

        assert_predicate response, :error?
        assert_match(/boom/, response.content.first[:text])
        assert_empty Dir.glob(File.join(flows_dir, "**", "stable.json"))
      end

      def test_promotes_nothing_when_flow_test_of_other_flow_using_the_action_fails
        write_flow_stable("orders/refund", { "charge" => { "paid" => nil } })
        write_flow_test("orders/refund", failing_test)
        write_approved("orders/purchase", { "charge" => { "paid" => nil } })

        response = PromoteFlows.call(flow_names: ["orders/purchase"], server_context: {})

        assert_predicate response, :error?
        assert_match(/boom/, response.content.first[:text])
        assert_path_exists flow_approved_path("orders/purchase")
      end

      def test_promotes_when_action_tests_pass
        write_approved("orders/purchase", { "charge" => { "paid" => nil } })
        write_action_test("charge", passing_test)

        response = PromoteFlows.call(flow_names: ["orders/purchase"], server_context: {})

        refute_predicate response, :error?
        assert_path_exists flow_stable_path("orders/purchase")
      end

      private

      def write_approved(flow_name, graph)
        write_flow_approved(flow_name, graph)
        graph.each { |action_name, transitions| write_action_with_results(action_name, transitions.keys) }
      end

      def write_action_with_results(action_name, results)
        write_action_file(action_name, <<~RUBY)
          module #{action_name.capitalize}
            class Action
              RESULTS = %i[#{results.join(" ")}].freeze
            end
          end
        RUBY
      end

      def passing_test
        <<~RUBY
          require "minitest/autorun"

          class PromotePassingTest < Minitest::Test
            def test_passes
              assert true
            end
          end
        RUBY
      end

      def failing_test
        <<~RUBY
          require "minitest/autorun"

          class PromoteFailingTest < Minitest::Test
            def test_fails
              assert false, "boom"
            end
          end
        RUBY
      end
    end
  end
end
