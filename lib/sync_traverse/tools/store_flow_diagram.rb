module SyncTraverse
  module Tools
    class StoreFlowDiagram < FlowBase
      tool_name "store_flow_diagram"
      description "Saves the Mermaid flowchart diagram of the flow draft, to be displayed alongside it and promoted together with it. Requires a draft: call it after updating the flow with update_flow. Rejected when the flow is approved: call reopen_draft first."
      input_schema(
        properties: {
          flow_name: FLOW_NAME_SCHEMA,
          diagram: {
            type: "string",
            description: "The complete Mermaid flowchart diagram source."
          }
        },
        required: %w[flow_name diagram]
      )

      def self.call(flow_name:, diagram:, server_context:)
        with_valid_format(flow_names: [flow_name]) do
          return error_response("Flow #{flow_name} is approved; call reopen_draft to change the diagram") if approved?(flow_name)
          return error_response("No draft for flow #{flow_name}; call update_flow first") unless draft?(flow_name)

          write_file(flow_draft_diagram_path(flow_name), diagram)
          text_response("Success")
        end
      end
    end
  end
end
