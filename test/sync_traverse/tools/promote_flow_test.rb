require "test_helper"

module SyncTraverse
  module Tools
    class PromoteFlowTest < SyncTraverse::TestCase
      def test_replaces_stable_flow_with_approved_flow
        write_flow_stable("orders/purchase", { "a" => { "ok" => nil } })
        write_flow_approved("orders/purchase", { "a" => { "ok" => "b" }, "b" => {} })

        response = PromoteFlow.call(flow_name: "orders/purchase", server_context: {})

        refute_predicate response, :error?
        assert_equal({ "a" => { "ok" => "b" }, "b" => {} }, JSON.parse(File.read(flow_stable_path("orders/purchase"))))
      end

      def test_leaves_only_stable_flow
        write_flow_approved("orders/purchase", { "a" => { "ok" => nil } })

        PromoteFlow.call(flow_name: "orders/purchase", server_context: {})

        refute_path_exists flow_approved_path("orders/purchase")
        refute_path_exists flow_draft_path("orders/purchase")
      end

      def test_replaces_diagram_with_approved_diagram
        write_flow_approved("orders/purchase", { "a" => { "ok" => nil } })
        File.write(flow_stable_diagram_path("orders/purchase"), "old")
        File.write(flow_approved_diagram_path("orders/purchase"), "new")

        PromoteFlow.call(flow_name: "orders/purchase", server_context: {})

        assert_equal "new", File.read(flow_stable_diagram_path("orders/purchase"))
        refute_path_exists flow_approved_diagram_path("orders/purchase")
      end

      def test_makes_flow_stable_phase
        write_flow_approved("orders/purchase", { "a" => { "ok" => nil } })
        PromoteFlow.call(flow_name: "orders/purchase", server_context: {})

        response = GetFlow.call(flow_name: "orders/purchase", server_context: {})

        assert_equal "Phase: stable", response.content.last[:text]
      end

      def test_deletes_flow_when_approved_flow_has_no_nodes
        write_flow_stable("orders/purchase", { "a" => { "ok" => nil } })
        write_flow_approved("orders/purchase", {})

        response = PromoteFlow.call(flow_name: "orders/purchase", server_context: {})

        refute_predicate response, :error?
        refute File.directory?(File.join(flows_dir, "orders"))
      end

      def test_rejects_draft_that_was_not_approved
        write_flow_stable("orders/purchase", { "a" => { "ok" => nil } })
        write_flow_draft("orders/purchase", { "a" => { "ok" => "b" }, "b" => {} })

        response = PromoteFlow.call(flow_name: "orders/purchase", server_context: {})

        assert_predicate response, :error?
        assert_equal({ "a" => { "ok" => nil } }, JSON.parse(File.read(flow_stable_path("orders/purchase"))))
      end
    end
  end
end
