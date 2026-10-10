require "open3"

module SyncTraverse
  module Tools
    class RunTests < NodeCodeBase
      TESTS_RUNNER = File.expand_path("../tests_runner.rb", __dir__)

      tool_name "run_tests"
      description "Runs tests in one application process. For every given flow it runs the flow test, which checks for every node of the flow that the outcomes used by the flow are exactly the outcomes declared in the OUTCOMES constant of the node. For every given node it runs the Minitest tests of the node (test files in the test directory of the node)."
      input_schema(
        properties: {
          nodes: {
            type: "array",
            items: { type: "string" },
            description: "Names of the nodes whose tests to run. Each must be a relative path; may be namespaced with a path, for example 'orders/validate_order'."
          },
          flows: {
            type: "array",
            items: { type: "string" },
            description: "Names of the flows whose flow tests to run. Each must be a relative path; may be namespaced with a path, for example 'orders/purchase'."
          }
        }
      )

      class << self
        def call(server_context:, nodes: [], flows: [])
          nodes = nodes.uniq
          flows = flows.uniq

          with_valid_format(flow_names: flows, node_names: nodes) do
            missing_flows = flows.reject { |flow| File.exist?(flow_definition_path(flow)) }
            return error_response("Flow not found: #{missing_flows.join(", ")}") if missing_flows.any?

            test_files = nodes.to_h { |node| [node, node_test_files(node)] }
            untested_nodes = test_files.select { |_, files| files.empty? }.keys
            return error_response("No tests found for node: #{untested_nodes.join(", ")}") if untested_nodes.any?

            run(
              nodes_dir: File.expand_path(nodes_dir),
              flows: flows.to_h { |flow| [flow, File.expand_path(flow_definition_path(flow))] },
              test_files: test_files.values.flatten.map { |file| File.expand_path(file) }
            )
          end
        end

        private

        def node_test_files(node)
          node_files(node).filter_map { |file| node_file_path(node, file) if test_file?(file) }
        end

        def run(options)
          stdout, stderr, status = Open3.capture3("bundle", "exec", "ruby", TESTS_RUNNER, JSON.generate(options))

          if status.success?
            text_response(utf8(stdout))
          else
            error_response([stdout, stderr].filter_map { |output| utf8(output) unless output.empty? }.join("\n"))
          end
        end

        def utf8(output)
          output.dup.force_encoding(Encoding::UTF_8).scrub
        end
      end
    end
  end
end
