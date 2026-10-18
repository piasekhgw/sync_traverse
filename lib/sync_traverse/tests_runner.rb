# Script run in a separate process by Tools::RunTests.
# Usage: ruby tests_runner.rb OPTIONS_JSON
# OPTIONS_JSON: {"root_dir": "...", "actions_dir": "...", "flows": {"flow_name": "flow_file_path"}, "test_files": ["..."]}
# test_files: tests of the actions and flow tests of the flows.
require "json"
require_relative "flow_results_test"
require_relative "config"
require_relative "runner"

options = JSON.parse(ARGV.shift)

SyncTraverse.config = SyncTraverse::Config.new(options.fetch("root_dir"))

options.fetch("flows").each do |flow_name, flow_file_path|
  SyncTraverse::FlowResultsTest.build(flow_name, flow_file_path, options.fetch("actions_dir"))
end

options.fetch("test_files").each { |file| require file }
