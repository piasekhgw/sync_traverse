module GraphFlow
  module Tools
    class RemoveEdges < Base
      description "Removes edges from the flow. Nodes that become isolated are removed automatically."
      parameters do
        string :flow_name, description: "The flow name."
        array :edges, of: Schemas::Edge
      end

      def execute(flow_name:, edges:)
        flow = get_flow(flow_name)

        flow.remove_edges(edges.map { |edge| edge.values_at("source", "target", "source_outcome") })

        save_flow(flow_name, flow)
      end
    end
  end
end
