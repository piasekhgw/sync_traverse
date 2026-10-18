module SyncTraverse
  module Tools
    class FlowBase < Base
      FLOW_NAME_SCHEMA = {
        type: "string",
        description: "The flow name. Must be a relative path; may be namespaced with a path, for example 'orders/purchase'."
      }.freeze

      class << self
        private

        def flow_test_file_path(flow_name, file_name)
          File.join(flow_tests_dir, flow_name, file_name)
        end

        def flow_exists?(flow_name)
          File.exist?(flow_definition_path(flow_name))
        end

        def read_flow(flow_name)
          SyncTraverse::Flow.new(flow_exists?(flow_name) ? read_json(flow_definition_path(flow_name)) : {}).to_h
        end

        def flow_test_file_names(flow_name)
          dir_file_names(File.join(flow_tests_dir, flow_name)).sort
        end

        def save_flow(flow_name, flow)
          write_file(flow_definition_path(flow_name), JSON.pretty_generate(flow.to_h))
          write_file(flow_diagram_path(flow_name), flow.to_mermaid)
        end

        def delete_flow(flow_name)
          [flows_dir, flow_tests_dir].each do |root|
            path = File.join(root, flow_name)
            FileUtils.rm_rf(path)

            dir = File.dirname(path)
            while dir.start_with?("#{root}/") && Dir.exist?(dir) && Dir.empty?(dir)
              Dir.rmdir(dir)
              dir = File.dirname(dir)
            end
          end
        end
      end
    end
  end
end
