require "test_helper"

module GraphFlow
  module Tools
    class StoreFlowDiagramTest < GraphFlow::TestCase
      def test_saves_diagram_next_to_flow_definition
        response = StoreFlowDiagram.call(
          flow_name: "orders/purchase",
          diagram: "flowchart TD\n  a --> b",
          server_context: {}
        )

        refute response.error?
        assert_equal "ok", response.content.first[:text]
        assert_equal "flowchart TD\n  a --> b", File.read(flow_diagram_path("orders/purchase"))
      end

      def test_overwrites_existing_diagram
        FileUtils.mkdir_p(File.dirname(flow_diagram_path("orders/purchase")))
        File.write(flow_diagram_path("orders/purchase"), "old diagram")

        StoreFlowDiagram.call(flow_name: "orders/purchase", diagram: "new diagram", server_context: {})

        assert_equal "new diagram", File.read(flow_diagram_path("orders/purchase"))
      end

      def test_rejects_invalid_flow_name
        response = StoreFlowDiagram.call(flow_name: "../escape", diagram: "flowchart TD", server_context: {})

        assert response.error?
        assert_equal "Invalid name(s): ../escape", response.content.first[:text]
      end
    end
  end
end
