require "minitest/autorun"
require "fileutils"
require "tmpdir"
require "json"
require "sync_braid"

module SyncBraid
  class TestCase < Minitest::Test
    def setup
      @tmp_dir = Dir.mktmpdir("sync_braid_test")

      SyncBraid.configure do |config|
        config.flows_dir = File.join(@tmp_dir, "flows")
        config.nodes_dir = File.join(@tmp_dir, "nodes")
        config.node_tests_dir = File.join(@tmp_dir, "node_tests")
      end
    end

    def teardown
      FileUtils.remove_entry(@tmp_dir)
    end

    private

    def flows_dir
      SyncBraid.config.flows_dir
    end

    def nodes_dir
      SyncBraid.config.nodes_dir
    end

    def flow_definition_path(flow_name)
      File.join(flows_dir, flow_name, "definition.json")
    end

    def flow_diagram_path(flow_name)
      File.join(flows_dir, flow_name, "diagram.mmd")
    end

    def node_path(node_name)
      File.join(nodes_dir, "#{node_name}.rb")
    end

    def node_test_path(node_name, suffix = "test.rb")
      File.join(SyncBraid.config.node_tests_dir, "#{node_name}_#{suffix}")
    end

    def write_flow_definition(flow_name, definition)
      path = flow_definition_path(flow_name)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, JSON.generate(definition))
    end

    def write_node_code(node_name, code)
      path = node_path(node_name)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, code)
      require path
    end

    def write_node_test(node_name, code, suffix: "test.rb")
      path = node_test_path(node_name, suffix)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, code)
    end
  end
end
