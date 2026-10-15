# Script run in a separate process by Tools::RunTests.
# Usage: ruby tests_runner.rb OPTIONS_JSON
# OPTIONS_JSON: {"root_dir": "...", "actions_dir": "...", "flows": {"flow_name": "flow_file_path"}, "test_files": ["..."]}
# test_files: tests of the actions and flow tests of the flows.
require "json"
require_relative "flow_results_test"
require_relative "config"
require_relative "runner"

options = JSON.parse(ARGV.shift)

# Flow tests run the graph being implemented: approved, else draft, else stable.
SyncTraverse.config = SyncTraverse::Config.new(options.fetch("root_dir"))
SyncTraverse.config.flow_phases = SyncTraverse::Config::FLOW_PHASES

options.fetch("flows").each do |flow_name, flow_file_path|
  SyncTraverse::FlowResultsTest.build(flow_name, flow_file_path, options.fetch("actions_dir"))
end

options.fetch("test_files").each { |file| require file }
