require "test_helper"

module SyncTraverse
  module Tools
    class StoreFlowDiagramTest < SyncTraverse::TestCase
      def test_saves_draft_diagram_next_to_draft_flow
        write_flow_draft("orders/purchase", { "a" => { "ok" => nil } })

        response = StoreFlowDiagram.call(
          flow_name: "orders/purchase",
          diagram: "flowchart TD\n  a --> b",
          server_context: {}
        )

        assert_equal "Success", response.content.first[:text]
        assert_equal "flowchart TD\n  a --> b", File.read(flow_draft_diagram_path("orders/purchase"))
        refute_path_exists flow_stable_diagram_path("orders/purchase")
      end

      def test_rejects_approved_flow
        write_flow_approved("orders/purchase", { "a" => { "ok" => nil } })

        response = StoreFlowDiagram.call(flow_name: "orders/purchase", diagram: "flowchart TD", server_context: {})

        assert_predicate response, :error?
        assert_equal "Flow orders/purchase is approved; call reopen_draft to change the diagram", response.content.first[:text]
        refute_path_exists flow_approved_diagram_path("orders/purchase")
      end

      def test_rejects_flow_without_draft
        response = StoreFlowDiagram.call(flow_name: "orders/purchase", diagram: "flowchart TD", server_context: {})

        assert_predicate response, :error?
        assert_equal "No draft for flow orders/purchase; call update_flow first", response.content.first[:text]
      end

      def test_overwrites_existing_diagram
        write_flow_draft("orders/purchase", { "a" => { "ok" => nil } })
        File.write(flow_draft_diagram_path("orders/purchase"), "old diagram")

        StoreFlowDiagram.call(flow_name: "orders/purchase", diagram: "new diagram", server_context: {})

        assert_equal "new diagram", File.read(flow_draft_diagram_path("orders/purchase"))
      end

      def test_rejects_invalid_flow_name
        response = StoreFlowDiagram.call(flow_name: "../escape", diagram: "flowchart TD", server_context: {})

        assert_predicate response, :error?
        assert_equal "Invalid name(s): ../escape", response.content.first[:text]
      end
    end
  end
end
