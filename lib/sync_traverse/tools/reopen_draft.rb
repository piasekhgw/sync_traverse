module SyncTraverse
  module Tools
    class ReopenDraft < FlowBase
      tool_name "reopen_draft"
      description "Returns the approved flow to the draft phase by renaming approved.json back to draft.json (and approved.mmd to draft.mmd). update_flow works again. Use it when the implementation requires changing the graph."
      input_schema(
        properties: {
          flow_name: FLOW_NAME_SCHEMA
        },
        required: ["flow_name"]
      )

      def self.call(flow_name:, server_context:)
        with_valid_format(flow_names: [flow_name]) do
          return error_response("Flow #{flow_name} is not approved") unless approved?(flow_name)

          rename_if_exists(flow_approved_diagram_path(flow_name), flow_draft_diagram_path(flow_name))
          File.rename(flow_approved_path(flow_name), flow_draft_path(flow_name))
          text_response(
            "Success. Flow #{flow_name} is a draft again.",
            "Node code and tests were not reverted and may no longer match the stable flow until promote_flow. " \
            "Change the graph with update_flow, call approve_draft again and run_tests for the flow."
          )
        end
      end
    end
  end
end
