module SyncTraverse
  module Tools
    class ApproveDrafts < FlowBase
      tool_name "approve_drafts"
      description "Approves the drafts of the given flows in one all-or-nothing call by renaming draft.json to approved.json (and draft.mmd to approved.mmd). Call it only when the developer accepted the graphs and asked for the implementation. Requires a valid draft of every flow. Actions are shared by all flows and their RESULTS are one contract, so the call is rejected when an action has different results in different flows: the drafts of the call are compared with each other and with the stable versions of all other flows. Approve together all flows that change the results of a shared action. While approved.json exists update_flow is rejected; action code and tests are implemented against it. The stable flows (stable.json) are not changed."
      input_schema(
        properties: {
          flow_names: FLOW_NAMES_SCHEMA
        },
        required: ["flow_names"]
      )

      class << self
        def call(flow_names:, server_context:)
          flow_names = flow_names.uniq
          with_valid_format(flow_names: flow_names) do
            errors = flow_names.flat_map { |flow_name| draft_errors(flow_name) }
            errors = shared_results_conflicts(get_flows(flow_names)) if errors.empty?
            return error_response(errors.join("\n")) if errors.any?

            flow_names.each do |flow_name|
              rename_if_exists(flow_draft_diagram_path(flow_name), flow_approved_diagram_path(flow_name))
              File.rename(flow_draft_path(flow_name), flow_approved_path(flow_name))
            end
            text_response("Success. Approved flows: #{flow_names.join(", ")}.")
          end
        end

        private

        def draft_errors(flow_name)
          return ["Flow #{flow_name} is already approved"] if approved?(flow_name)
          return ["No draft for flow #{flow_name}; call update_flow first"] unless draft?(flow_name)

          GraphValidator.new(get_flow(flow_name)).call.map { |error| "Flow #{flow_name}: #{error}" }
        end
      end
    end
  end
end
