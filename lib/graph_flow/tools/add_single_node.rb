module GraphFlow
  module Tools
    class AddSingleNode < Base
      tool_name "add_single_node"
      description "Adds a single node to the flow. Use only when the complete flow has exactly one node."
      input_schema(
        properties: {
          flow_name: { type: "string", description: "The flow name. Must be a relative path; may be namespaced with a path, for example 'orders/validate_order'." },
          node: { type: "string", description: "The snake_case node name." }
        },
        required: ["flow_name", "node"]
      )

      def self.call(flow_name:, node:, server_context:)
        flow = get_flow(flow_name)

        flow.add_node(node)

        save_flow(flow_name, flow)
        text_response(flow.definition)
      end
    end
  end
end
