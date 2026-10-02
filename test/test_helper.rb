require "minitest/autorun"
require "fileutils"
require "tmpdir"
require "json"
require "dotenv"

Dotenv.load(File.expand_path("../.env.test", __dir__))

require "sync_traverse"

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
      [flows_dir, nodes_dir, SyncTraverse.config.node_tests_dir].each { |dir| FileUtils.rm_rf(dir) }
    end

    def flows_dir
      SyncTraverse.config.flows_dir
    end

    def nodes_dir
      SyncTraverse.config.nodes_dir
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
      File.join(SyncTraverse.config.node_tests_dir, "#{node_name}_#{suffix}")
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
      load path
    end

    def write_node_test(node_name, code, suffix: "test.rb")
      path = node_test_path(node_name, suffix)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, code)
    end
  end
end
