require "open3"

module SyncTraverse
  module Tools
    class RunNodeTests < NodeCodeBase
      tool_name "run_node_tests"
      description "Runs the Minitest tests (*test.rb files in node directories) of all nodes used by a flow."
      input_schema(
        properties: {
          flow_name: {
            type: "string",
            description: "The flow name. Must be a relative path; may be namespaced with a path, for example 'orders/purchase'."
          }
        },
        required: ["flow_name"]
      )

      class << self
        def call(flow_name:, server_context:)
          with_input_validation(flow_name: flow_name) do
            test_files = test_files_for(flow_name)

            return error_response("No node tests found for flow: #{flow_name}") if test_files.empty?

            run_tests(test_files)
          end
        end

        private

        def run_tests(test_files)
          command = [
            "bundle",
            "exec",
            "ruby",
            "-e",
            test_files.map { |file| "require #{File.expand_path(file).inspect}" }.join(";")
          ]

          stdout, stderr, status = Open3.capture3(*command)

          if status.success?
            text_response(utf8(stdout))
          else
            error_response([stdout, stderr].filter_map { |output| utf8(output) unless output.empty? }.join("\n"))
          end
        end

        def utf8(output)
          output.dup.force_encoding(Encoding::UTF_8).scrub
        end

        def test_files_for(flow_name)
          get_flow(flow_name).definition.keys.flat_map do |node|
            node_files(node).filter_map { |file| node_file_path(node, file) if test_file?(file) }
          end
        end
      end
    end
  end
end
