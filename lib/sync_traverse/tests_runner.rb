# Script run in a separate process by Tools::RunTests.
# Usage: ruby tests_runner.rb OPTIONS_JSON
# OPTIONS_JSON: {"nodes_dir": "...", "flows": {"flow_name": "flow_file_path"}, "test_files": ["..."]}
require "json"
require_relative "flow_test"

options = JSON.parse(ARGV.shift)

options.fetch("flows").each do |flow_name, flow_file_path|
  SyncTraverse::FlowTest.build(flow_name, flow_file_path, options.fetch("nodes_dir"))
end

options.fetch("test_files").each { |file| require file }
