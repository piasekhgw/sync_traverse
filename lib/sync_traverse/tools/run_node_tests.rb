require "open3"

module SyncTraverse
  module Tools
    class RunNodeTests < FlowBase
      tool_name "run_node_tests"
      description "Runs unit tests for all nodes used by a flow."
      input_schema(
        properties: {
          flow_name: {
            type: "string",
            description: "The flow name. Must be a relative path; may be namespaced with a path, for example 'orders/purchase'."
          },
          testing_framework: {
            type: "string",
            enum: %w[rspec minitest],
            description: "The testing framework to use for running the node tests."
          }
        },
        required: %w[flow_name testing_framework]
      )

      class << self
        def call(flow_name:, testing_framework:, server_context:)
          with_input_validation(flow_name: flow_name) do
            test_files = test_files_for(flow_name, testing_framework)

            return error_response("No node tests found for flow: #{flow_name}") if test_files.empty?

            run_tests(test_files, testing_framework)
          end
        end

        private

        def run_tests(test_files, testing_framework)
          command =
            case testing_framework
            when "rspec"
              [
                "bundle",
                "exec",
                "rspec",
                *test_files
              ]
            when "minitest"
              [
                "bundle",
                "exec",
                "ruby",
                "-Itest",
                "-e",
                test_files.map { |file| "require #{File.expand_path(file).inspect}" }.join(";")
              ]
            end

          stdout, stderr, status = Open3.capture3(*command)

          if status.success?
            text_response(stdout)
          else
            error_response([stdout, stderr].reject(&:empty?).join("\n"))
          end
        end

        def test_files_for(flow_name, testing_framework)
          tests_suffix = testing_framework == "rspec" ? "spec.rb" : "test.rb"
          nodes = get_flow(flow_name).definition.keys

          nodes.filter_map do |node|
            path = File.join(SyncTraverse.config.node_tests_dir, "#{node}_#{tests_suffix}")
            path if File.exist?(path)
          end
        end
      end
    end
  end
end
