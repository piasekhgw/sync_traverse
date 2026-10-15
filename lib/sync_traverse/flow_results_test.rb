require "json"
require "minitest/autorun"
require "active_support/core_ext/string/inflections"

module SyncTraverse
  # Results check of a flow, run in the application process (see Tools::RunTests).
  # For every action of the flow it checks that the results used by the flow are exactly the results
  # declared in the RESULTS constant of the action.
  class FlowResultsTest < Minitest::Test
    def self.build(flow_name, flow_file_path, actions_dir)
      graph = JSON.parse(File.read(flow_file_path))

      Class.new(self) do
        define_singleton_method(:name) { "FlowResultsTest(#{flow_name})" }

        graph.each do |action_name, transitions|
          define_method("test_#{action_name}_results_match_action_results") do
            assert_results_match(action_name, transitions.keys, actions_dir)
          end
        end
      end
    end

    private

    def assert_results_match(action_name, flow_results, actions_dir)
      require File.join(actions_dir, action_name, "action")
      action = "#{action_name}/action".camelize.constantize

      assert action.const_defined?(:RESULTS, false), "#{action} must define RESULTS"

      declared = action::RESULTS.map(&:to_s)

      assert_empty flow_results - declared, "Result(s) used by the flow but not declared in #{action}::RESULTS (#{declared.join(", ")})"
      assert_empty declared - flow_results, "Result(s) declared in #{action}::RESULTS but without a transition in the flow (#{flow_results.join(", ")})"
    end
  end
end
