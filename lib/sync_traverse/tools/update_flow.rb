module SyncTraverse
  module Tools
    class UpdateFlow < FlowBase
      tool_name "update_flow"
      description "Updates the flow in a single step: removes edges first, then adds edges. Referenced nodes are created automatically; nodes that become isolated are removed automatically. A flow left without nodes is deleted. Code of nodes no longer used by any flow is never deleted automatically; delete it explicitly with update_node_code only when the user decides to."
      input_schema(
        properties: {
          flow_name: {
            type: "string",
            description: "The flow name. Must be a relative path; may be namespaced with a path, for example 'orders/purchase'."
          },
          remove_edges: {
            type: "array",
            items: EDGE_SCHEMA,
            description: "Edges to remove."
          },
          add_edges: {
            type: "array",
            items: EDGE_SCHEMA,
            description: "Edges to add, including terminal ones."
          }
        },
        required: ["flow_name"]
      )

      def self.call(flow_name:, server_context:, remove_edges: [], add_edges: [])
        with_valid_format(flow_names: [flow_name], node_names: edge_node_names(remove_edges + add_edges)) do
          flow = get_flow(flow_name)

          flow.remove_edges(remove_edges)
          flow.add_edges(add_edges)

          graph_errors = GraphValidator.new(flow.definition).call
          return error_response(graph_errors.join("\n")) if graph_errors.any?

          if flow.definition.empty?
            delete_flow(flow_name)
            return text_response("Success. Flow has no nodes left and was deleted.")
          end

          save_flow(flow_name, flow)
          text_response("Success")
        end
      rescue Flow::ConflictError => e
        error_response(e.message)
      end
    end
  end
end
