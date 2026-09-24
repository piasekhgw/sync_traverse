module GraphFlow
  module Tools
    class AddEdges < Base
      description "Adds edges to the flow. Referenced nodes are created automatically."
      parameters do
        array :edges, of: Schemas::Edge
      end

      def self.tool_name
        "add_edges"
      end

      def execute(flow_name:, edges:)
        flow = get_flow(flow_name)

        flow.add_edges(edges.map { |edge| edge.values_at(:source, :target, :source_outcome) })

        save_flow(flow_name, flow)
      end
    end
  end
end
