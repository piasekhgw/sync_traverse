module SyncTraverse
  module Tools
    class FlowBase < Base
      TRANSITION_SCHEMA = {
        type: "object",
        properties: {
          source: { type: "string", description: "Source action name." },
          target: { type: %w[string null], description: "Target action name, or null if this result ends the flow." },
          source_result: { type: "string", description: "Result returned by the source action that selects this transition." }
        },
        required: %w[source target source_result]
      }.freeze

      FLOW_NAME_SCHEMA = {
        type: "string",
        description: "The flow name. Must be a relative path; may be namespaced with a path, for example 'orders/purchase'."
      }.freeze

      class << self
        private

        def save_flow(flow_name, flow)
          write_file(flow_draft_path(flow_name), JSON.pretty_generate(flow.to_h))
        end

        def discard_draft_files(flow_name)
          FileUtils.rm_f(
            [flow_draft_path(flow_name), flow_draft_diagram_path(flow_name), flow_approved_path(flow_name), flow_approved_diagram_path(flow_name)]
          )
          delete_flow(flow_name) unless stable?(flow_name)
        end

        def rename_if_exists(from, to)
          File.rename(from, to) if File.exist?(from)
        end

        def delete_flow(flow_name)
          path = flow_path(flow_name)
          FileUtils.rm_rf(path)

          dir = File.dirname(path)
          while dir.start_with?("#{flows_dir}/") && Dir.exist?(dir) && Dir.empty?(dir)
            Dir.rmdir(dir)
            dir = File.dirname(dir)
          end
        end

        def transition_action_names(transitions)
          transitions.flat_map { |transition| transition.values_at(:source, :target) }
        end
      end
    end
  end
end
