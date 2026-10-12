module SyncTraverse
  module Tools
    class PromoteFlow < FlowBase
      tool_name "promote_flow"
      description "Promotes the approved flow to stable: atomically replaces stable.json and stable.mmd with approved.json and approved.mmd, which then no longer exist. An approved flow without nodes deletes the flow instead. Requires the approved phase. Call it only after the implementation is ready and run_tests passes; it does not run tests itself."
      input_schema(
        properties: {
          flow_name: FLOW_NAME_SCHEMA
        },
        required: ["flow_name"]
      )

      class << self
        def call(flow_name:, server_context:)
          with_valid_format(flow_names: [flow_name]) do
            return error_response("Flow #{flow_name} is not approved; call approve_draft first") unless approved?(flow_name)

            if get_flow(flow_name).empty?
              delete_flow(flow_name)
              return text_response("Success. Approved flow has no nodes; flow #{flow_name} was deleted.")
            end

            promote_approved(flow_name)
            text_response("Success. Flow #{flow_name} was promoted.")
          end
        end

        private

        def promote_approved(flow_name)
          rename_if_exists(flow_approved_diagram_path(flow_name), flow_stable_diagram_path(flow_name))
          File.rename(flow_approved_path(flow_name), flow_stable_path(flow_name))
        end
      end
    end
  end
end
