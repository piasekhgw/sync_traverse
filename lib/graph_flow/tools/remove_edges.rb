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
        flow = get_flow(flow_name)

        flow.remove_edges(edges.map { |edge| edge.values_at(:source, :target, :source_outcome) })

        save_flow(flow_name, flow)
        text_response(flow.definition)
      end
    end
  end
end
