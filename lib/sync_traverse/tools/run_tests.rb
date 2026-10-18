require "open3"

module SyncTraverse
  module Tools
    class RunTests < Base
      TESTS_RUNNER = File.expand_path("../tests_runner.rb", __dir__)

      tool_name "run_tests"
      description "Validates the whole project in one application process: the results check of every flow, which verifies for every action of the flow that the action exists and that the results used by the flow are exactly the results declared in the RESULTS constant of the action; the tests of every action (test/actions/); and the flow tests of every flow (test/flows/), which run the flows through the real actions with SyncTraverse::Runner. Flows and actions may be inconsistent while you work; call this to find what still does not match."

      class << self
        def call(server_context:)
          flows = Dir.glob(flow_definition_path("**")).to_h do |path|
            [File.dirname(path).delete_prefix("#{flows_dir}/"), path]
          end

          run(
            root_dir: SyncTraverse.config.root_dir,
            actions_dir: actions_dir,
            flows: flows,
            test_files: test_files(action_tests_dir) + test_files(flow_tests_dir)
          )
        end

        private

        def test_files(dir)
          Dir.glob(File.join(dir, "**", "*.rb")).select { |path| test_file?(File.basename(path)) }.sort
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
