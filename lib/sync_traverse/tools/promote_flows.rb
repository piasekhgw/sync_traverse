module SyncTraverse
  module Tools
    class PromoteFlows < FlowBase
      tool_name "promote_flows"
      description "Promotes the approved flows to stable in one all-or-nothing call: replaces stable.json and stable.mmd of each flow with approved.json and approved.mmd, which then no longer exist. An approved flow without actions deletes the flow instead. Every flow must be in the approved phase. Like approve_drafts, the call is rejected when an action has different results in different flows: the approved flows of the call are compared with each other and with the stable versions of all other flows. Promote together the flows that were approved together. Call it only after the implementation is ready; it runs the results check and flow tests of the flows and the tests of their actions itself and promotes nothing if any of them fails."
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
            errors = flow_names.reject { |flow_name| approved?(flow_name) }
                               .map { |flow_name| "Flow #{flow_name} is not approved; call approve_drafts first" }
            errors = shared_results_conflicts(get_flows(flow_names)) if errors.empty?
            return error_response(errors.join("\n")) if errors.any?

            tests = run_tests(flow_names)
            return error_response("Tests failed; nothing was promoted.\n#{tests.content.first[:text]}") if tests.error?

            text_response(*flow_names.map { |flow_name| promote(flow_name) })
          end
        end

        private

        def run_tests(flow_names)
          action_names = get_flows(flow_names).values.flat_map(&:keys).uniq
          RunTests.call(flows: flow_names, actions: RunTests.actions_with_tests(action_names), server_context: {})
        end

        def promote(flow_name)
          if get_flow(flow_name).empty?
            delete_flow(flow_name)
            return "Success. Approved flow has no actions; flow #{flow_name} was deleted."
          end

          rename_if_exists(flow_approved_diagram_path(flow_name), flow_stable_diagram_path(flow_name))
          File.rename(flow_approved_path(flow_name), flow_stable_path(flow_name))
          "Success. Flow #{flow_name} was promoted."
        end
      end
    end
  end
end
