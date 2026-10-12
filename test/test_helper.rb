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
      [flows_dir, nodes_dir, tests_dir].each { |dir| FileUtils.rm_rf(dir) }
    end

    def flows_dir
      SyncTraverse.config.flows_dir
    end

    def nodes_dir
      SyncTraverse.config.nodes_dir
    end

    def tests_dir
      SyncTraverse.config.tests_dir
    end

    def flow_stable_path(flow_name)
      File.join(flows_dir, flow_name, "stable.json")
    end

    def flow_stable_diagram_path(flow_name)
      File.join(flows_dir, flow_name, "stable.mmd")
    end

    def flow_draft_path(flow_name)
      File.join(flows_dir, flow_name, "draft.json")
    end

    def flow_draft_diagram_path(flow_name)
      File.join(flows_dir, flow_name, "draft.mmd")
    end

    def flow_approved_path(flow_name)
      File.join(flows_dir, flow_name, "approved.json")
    end

    def flow_approved_diagram_path(flow_name)
      File.join(flows_dir, flow_name, "approved.mmd")
    end

    def node_path(node_name, file_name = "node.rb")
      File.join(nodes_dir, node_name, file_name)
    end

    def node_test_path(node_name, file_name = "test.rb")
      File.join(tests_dir, node_name, file_name)
    end

    def write_flow_stable(flow_name, graph)
      write_code_file(flow_stable_path(flow_name), JSON.generate(graph))
    end

    def write_flow_draft(flow_name, graph)
      write_code_file(flow_draft_path(flow_name), JSON.generate(graph))
    end

    def write_flow_approved(flow_name, graph)
      write_code_file(flow_approved_path(flow_name), JSON.generate(graph))
    end

    def write_node_file(node_name, code, file_name: "node.rb")
      write_code_file(node_path(node_name, file_name), code)
    end

    def write_node_code(node_name, code)
      load write_node_file(node_name, code)
    end

    def write_node_test(node_name, code, file_name: "test.rb")
      write_code_file(node_test_path(node_name, file_name), code)
    end

    def write_code_file(path, code)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, code)
      path
    end
  end
end
