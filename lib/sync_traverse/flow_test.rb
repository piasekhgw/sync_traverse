require "json"
require "minitest/autorun"
require "active_support/core_ext/string/inflections"

module SyncTraverse
  # Flow test run in the application process (see Tools::RunTests).
  # For every node of the flow it checks that the outcomes used by the flow are exactly the outcomes
  # declared in the OUTCOMES constant of the node.
  class FlowTest < Minitest::Test
    def self.build(flow_name, definition_path, nodes_dir)
      definition = JSON.parse(File.read(definition_path))

      Class.new(self) do
        define_singleton_method(:name) { "FlowTest(#{flow_name})" }

        definition.each do |node_name, edges|
          define_method("test_#{node_name}_outcomes_match_node_outcomes") do
            assert_outcomes_match(node_name, edges.keys, nodes_dir)
          end
        end
      end
    end

    private

    def assert_outcomes_match(node_name, flow_outcomes, nodes_dir)
      require File.join(nodes_dir, node_name, "node")
      node = "#{node_name}/node".camelize.constantize

      assert node.const_defined?(:OUTCOMES, false), "#{node} must define OUTCOMES"

      declared = node::OUTCOMES.map(&:to_s)

      assert_empty flow_outcomes - declared, "Outcome(s) used by the flow but not declared in #{node}::OUTCOMES (#{declared.join(", ")})"
      assert_empty declared - flow_outcomes, "Outcome(s) declared in #{node}::OUTCOMES but without an edge in the flow (#{flow_outcomes.join(", ")})"
    end
  end
end
