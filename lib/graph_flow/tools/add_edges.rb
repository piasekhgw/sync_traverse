module GraphFlow
  module Tools
    class AddEdges < Base
      tool_name "add_edges"
      description "Adds edges to the flow. Referenced nodes are created automatically."
      input_schema(
        properties: {
          flow_name: { type: "string", description: "The flow name. Must be a relative path; may be namespaced with a path, for example 'orders/validate_order'." },
          edges: { type: "array", items: EDGE_SCHEMA }
        },
        required: ["flow_name", "edges"]
      )

      def self.call(flow_name:, edges:, server_context:)
        flow = get_flow(flow_name)

        flow.add_edges(edges.map { |edge| edge.values_at(:source, :target, :source_outcome) })

        save_flow(flow_name, flow)
        text_response(flow.definition)
      end
    end
  end
end
