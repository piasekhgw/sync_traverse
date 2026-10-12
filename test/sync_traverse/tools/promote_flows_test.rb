require "test_helper"

module SyncTraverse
  module Tools
    class PromoteFlowsTest < SyncTraverse::TestCase
      def test_replaces_stable_flow_with_approved_flow
        write_flow_stable("orders/purchase", { "a" => { "ok" => nil } })
        write_flow_approved("orders/purchase", { "a" => { "ok" => "b" }, "b" => {} })

        response = PromoteFlows.call(flow_names: ["orders/purchase"], server_context: {})

        refute_predicate response, :error?
        assert_equal({ "a" => { "ok" => "b" }, "b" => {} }, JSON.parse(File.read(flow_stable_path("orders/purchase"))))
      end

      def test_leaves_only_stable_flow
        write_flow_approved("orders/purchase", { "a" => { "ok" => nil } })

        PromoteFlows.call(flow_names: ["orders/purchase"], server_context: {})

        refute_path_exists flow_approved_path("orders/purchase")
        refute_path_exists flow_draft_path("orders/purchase")
      end

      def test_replaces_diagram_with_approved_diagram
        write_flow_approved("orders/purchase", { "a" => { "ok" => nil } })
        File.write(flow_stable_diagram_path("orders/purchase"), "old")
        File.write(flow_approved_diagram_path("orders/purchase"), "new")

        PromoteFlows.call(flow_names: ["orders/purchase"], server_context: {})

        assert_equal "new", File.read(flow_stable_diagram_path("orders/purchase"))
        refute_path_exists flow_approved_diagram_path("orders/purchase")
      end

      def test_makes_flow_stable_phase
        write_flow_approved("orders/purchase", { "a" => { "ok" => nil } })
        PromoteFlows.call(flow_names: ["orders/purchase"], server_context: {})

        response = GetFlow.call(flow_name: "orders/purchase", server_context: {})

        assert_equal "Phase: stable", response.content.last[:text]
      end

      def test_deletes_flow_when_approved_flow_has_no_actions
        write_flow_stable("orders/purchase", { "a" => { "ok" => nil } })
        write_flow_approved("orders/purchase", {})

        response = PromoteFlows.call(flow_names: ["orders/purchase"], server_context: {})

        refute_predicate response, :error?
        refute File.directory?(File.join(flows_dir, "orders"))
      end

      def test_rejects_draft_that_was_not_approved
        write_flow_stable("orders/purchase", { "a" => { "ok" => nil } })
        write_flow_draft("orders/purchase", { "a" => { "ok" => "b" }, "b" => {} })

        response = PromoteFlows.call(flow_names: ["orders/purchase"], server_context: {})

        assert_predicate response, :error?
        assert_equal({ "a" => { "ok" => nil } }, JSON.parse(File.read(flow_stable_path("orders/purchase"))))
      end

      def test_promotes_several_flows
        write_flow_approved("billing/invoice", { "charge" => { "paid" => nil } })
        write_flow_approved("orders/purchase", { "charge" => { "paid" => nil } })

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
        write_flow_approved("orders/purchase", { "charge" => { "paid" => nil, "declined" => nil } })

        response = PromoteFlows.call(flow_names: ["orders/purchase"], server_context: {})

        refute_predicate response, :error?
      end

      def test_deleted_flow_no_longer_counts_as_user_of_its_actions
        write_flow_stable("billing/invoice", { "charge" => { "paid" => nil } })
        write_flow_approved("billing/invoice", {})
        write_flow_approved("orders/purchase", { "charge" => { "declined" => nil } })

        response = PromoteFlows.call(flow_names: ["billing/invoice", "orders/purchase"], server_context: {})

        refute_predicate response, :error?
      end
    end
  end
end
