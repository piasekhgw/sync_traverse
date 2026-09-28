module GraphFlow
  module Tools
    class RemoveEdges < FlowBase
      tool_name "remove_edges"
      description "Removes edges from the flow. Nodes that become isolated are removed automatically."
      input_schema(
        properties: {
          flow_name: { type: "string", description: "The flow name. Must be a relative path; may be namespaced with a path, for example 'orders/purchase'." },
          edges: { type: "array", items: EDGE_SCHEMA }
        },
        required: ["flow_name", "edges"]
      )

      def self.call(flow_name:, edges:, server_context:)
        with_input_validation(flow_name: flow_name, node_names: edge_node_names(edges)) do
          flow = get_flow(flow_name)

          flow.remove_edges(edges)

          save_flow(flow_name, flow)
          text_response('ok')
        end
      end
    end
  end
end
