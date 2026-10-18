require "minitest/autorun"
require "fileutils"
require "tmpdir"
require "json"

require "sync_traverse"

test_root = File.expand_path("../tmp/test", __dir__)
FileUtils.mkdir_p(test_root)
SyncTraverse.config = SyncTraverse::Config.new(test_root)

module SyncTraverse
  class TestCase < Minitest::Test
    def setup
      cleanup_dirs
    end

    def teardown
      cleanup_dirs
    end

    private

    def cleanup_dirs
      [flows_dir, actions_dir, action_tests_dir, flow_tests_dir].each { |dir| FileUtils.rm_rf(dir) }
    end

    def flows_dir
      SyncTraverse.config.flows_dir
    end

    def actions_dir
      SyncTraverse.config.actions_dir
    end

    def action_tests_dir
      SyncTraverse.config.action_tests_dir
    end

    def flow_tests_dir
      SyncTraverse.config.flow_tests_dir
    end

    def flow_definition_path(flow_name)
      File.join(flows_dir, flow_name, "definition.json")
    end

    def flow_diagram_path(flow_name)
      File.join(flows_dir, flow_name, "definition.mmd")
    end

    def action_path(action_name, file_name = "action.rb")
      File.join(actions_dir, action_name, file_name)
    end

    def action_test_path(action_name, file_name = "test.rb")
      File.join(action_tests_dir, action_name, file_name)
    end

    def write_flow(flow_name, graph)
      write_code_file(flow_definition_path(flow_name), JSON.generate(graph))
    end

    def write_action_file(action_name, code, file_name: "action.rb")
      write_code_file(action_path(action_name, file_name), code)
    end

    def write_action_code(action_name, code)
      load write_action_file(action_name, code)
    end

    def write_action_test(action_name, code, file_name: "test.rb")
      write_code_file(action_test_path(action_name, file_name), code)
    end

    def flow_test_path(flow_name, file_name = "test.rb")
      File.join(flow_tests_dir, flow_name, file_name)
    end

    def write_flow_test(flow_name, code, file_name: "test.rb")
      write_code_file(flow_test_path(flow_name, file_name), code)
    end

    def with_default_external(encoding)
      original = Encoding.default_external
      Encoding.default_external = encoding
      yield
    ensure
      Encoding.default_external = original
    end

    def write_code_file(path, code)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, code)
      path
    end
  end
end
