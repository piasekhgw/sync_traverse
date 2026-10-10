module SyncTraverse
  module Tools
    class StoreFlowDiagram < FlowBase
      tool_name "store_flow_diagram"
      description "Saves a Mermaid flowchart diagram for the given flow, to be displayed alongside it. Call this after updating the flow with update_flow."
      input_schema(
        properties: {
          flow_name: {
            type: "string",
            description: "The flow name. Must be a relative path; may be namespaced with a path, for example 'orders/purchase'."
          },
          diagram: {
            type: "string",
            description: "The complete Mermaid flowchart diagram source."
          }
        },
        required: %w[flow_name diagram]
      )

      def self.call(flow_name:, diagram:, server_context:)
        with_valid_format(flow_names: [flow_name]) do
          write_file(flow_diagram_path(flow_name), diagram)
          text_response("Success")
        end
      end
    end
  end
end
