module SyncTraverse
  module Tools
    class ApproveDraft < FlowBase
      tool_name "approve_draft"
      description "Approves the flow draft by renaming draft.json to approved.json (and draft.mmd to approved.mmd). Call it only when the developer accepted the graph and asked for the implementation. Requires a valid draft. While approved.json exists update_flow is rejected; action code and tests are implemented against it. The stable flow (stable.json) is not changed."
      input_schema(
        properties: {
          flow_name: FLOW_NAME_SCHEMA
        },
        required: ["flow_name"]
      )

      def self.call(flow_name:, server_context:)
        with_valid_format(flow_names: [flow_name]) do
          return error_response("Flow #{flow_name} is already approved") if approved?(flow_name)
          return error_response("No draft for flow #{flow_name}; call update_flow first") unless draft?(flow_name)

          graph_errors = GraphValidator.new(get_flow(flow_name)).call
          return error_response(graph_errors.join("\n")) if graph_errors.any?

          rename_if_exists(flow_draft_diagram_path(flow_name), flow_approved_diagram_path(flow_name))
          File.rename(flow_draft_path(flow_name), flow_approved_path(flow_name))
          text_response("Success. Flow #{flow_name} is approved.")
        end
      end
    end
  end
end
