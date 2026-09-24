module GraphFlow
  module Tools
    class RemoveSingleNode < Base
      description "Removes the only node in the flow. Use only when the flow has exactly one node."
      parameters do
        string :flow_name, description: "The flow name."
        string :node, description: "The snake_case node name."
      end

      def execute(flow_name:, node:)
        flow = get_flow(flow_name)

        flow.remove_node(node)

        save_flow(flow_name, flow)
      end
    end
  end
end
