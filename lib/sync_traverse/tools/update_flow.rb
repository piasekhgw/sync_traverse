module SyncTraverse
  module Tools
    class UpdateFlow < FlowBase
      tool_name "update_flow"
      description "Updates the flow draft in a single step: removes edges first, then adds edges. The first update creates the draft as a copy of the stable flow (stable.json), which is never changed by this tool; promote_flow replaces it later. Referenced nodes are added to the graph automatically (their code is managed separately with update_node_code); nodes that become isolated are removed from the graph automatically. A draft left without nodes means the flow is to be deleted on promotion; if the flow has no stable version, the draft is simply discarded. Rejected when the flow is approved: call reopen_draft first. Node code is never deleted automatically; a node that no flow (stable, draft or approved) uses anymore can be deleted explicitly with update_node_code, only when the user decides to."
      input_schema(
        properties: {
          flow_name: FLOW_NAME_SCHEMA,
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
          return error_response("Flow #{flow_name} is approved; call reopen_draft to change the graph") if approved?(flow_name)

          flow = SyncTraverse::Flow.new(get_flow(flow_name))

          flow.remove_edges(remove_edges)
          flow.add_edges(add_edges)

          graph_errors = GraphValidator.new(flow.to_h).call
          return error_response(graph_errors.join("\n")) if graph_errors.any?

          if flow.to_h.empty?
            unless stable?(flow_name)
              discard_draft_files(flow_name)
              return text_response("Success. Flow has no nodes; there is nothing to draft.")
            end

            save_flow(flow_name, flow)
            return text_response("Success. Draft has no nodes left; promoting it deletes the flow.")
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
