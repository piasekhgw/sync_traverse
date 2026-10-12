module SyncTraverse
  module Tools
    class DiscardDraft < FlowBase
      tool_name "discard_draft"
      description "Discards the unpromoted change of the flow (draft.json or approved.json, with its diagram) and returns to the stable flow, which is not changed. For a flow that has no stable flow yet, the flow is removed entirely. Use it only when the developer abandons the change. Action code is never deleted."
      input_schema(
        properties: {
          flow_name: FLOW_NAME_SCHEMA
        },
        required: ["flow_name"]
      )

      def self.call(flow_name:, server_context:)
        with_valid_format(flow_names: [flow_name]) do
          return error_response("No draft or approved version for flow #{flow_name}") if !draft?(flow_name) && !approved?(flow_name)

          discard_draft_files(flow_name)
          return text_response("Success. Draft of flow #{flow_name} was discarded; the flow was removed.") unless stable?(flow_name)

          text_response(
            "Success. Draft of flow #{flow_name} was discarded.",
            "Action code and tests were not reverted and may no longer match the stable flow. " \
            "Call run_tests for the flow and for other flows using the changed actions, then fix or revert the actions that break them."
          )
        end
      end
    end
  end
end
