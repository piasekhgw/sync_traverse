module GraphFlow
  module Tools
    class AddSingleNode < Base
      description "Adds a single node to the flow. Use only when the complete flow has exactly one node."
      parameter :node, description: "The snake_case node name."

      def execute(flow_name:, node:)
        flow = get_flow(flow_name)

        flow.add_node(node)

        save_flow(flow_name, flow)
      end
    end
  end
end
