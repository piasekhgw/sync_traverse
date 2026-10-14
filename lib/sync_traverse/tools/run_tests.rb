require "open3"

module SyncTraverse
  module Tools
    class RunTests < ActionCodeBase
      TESTS_RUNNER = File.expand_path("../tests_runner.rb", __dir__)

      tool_name "run_tests"
      description "Runs tests in one application process. For every given flow it runs the flow test, which checks for every action of the flow that the results used by the flow are exactly the results declared in the RESULTS constant of the action. For every given action it runs the Minitest tests of the action (test files in the test directory of the action)."
      input_schema(
        properties: {
          actions: {
            type: "array",
            items: { type: "string" },
            description: "Names of the actions whose tests to run. Each must be a relative path; may be namespaced with a path, for example 'orders/validate_order'."
          },
          flows: {
            type: "array",
            items: { type: "string" },
            description: "Names of the flows whose flow tests to run. The approved flow is tested if it exists, else the draft, else the stable flow. Each must be a relative path; may be namespaced with a path, for example 'orders/purchase'."
          }
        }
      )

      class << self
        def call(server_context:, actions: [], flows: [])
          actions = actions.uniq
          flows = flows.uniq

          with_valid_format(flow_names: flows, action_names: actions) do
            missing_flows = flows.reject { |flow| File.exist?(current_flow_path(flow)) }
            return error_response("Flow not found: #{missing_flows.join(", ")}") if missing_flows.any?

            test_files = actions.to_h { |action| [action, action_test_files(action)] }
            untested_actions = test_files.select { |_, files| files.empty? }.keys
            return error_response("No tests found for action: #{untested_actions.join(", ")}") if untested_actions.any?

            run(
              actions_dir: File.expand_path(actions_dir),
              flows: flows.to_h { |flow| [flow, File.expand_path(current_flow_path(flow))] },
              test_files: test_files.values.flatten.map { |file| File.expand_path(file) }
            )
          end
        end

        def actions_with_tests(action_names)
          action_names.reject { |action| action_test_files(action).empty? }
        end

        private

        def action_test_files(action)
          action_files(action).filter_map { |file| action_file_path(action, file) if test_file?(file) }
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
