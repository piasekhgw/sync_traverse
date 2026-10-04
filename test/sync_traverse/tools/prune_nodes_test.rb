require "test_helper"

module SyncTraverse
  module Tools
    class PruneNodesTest < SyncTraverse::TestCase
      def test_removes_node_unused_by_any_flow
        write_node_code("orders/unused_node", "'code'")

        response = PruneNodes.call(server_context: {})

        refute_path_exists node_path("orders/unused_node")
        assert_includes response.content.first[:text], "unused_node.rb"
      end

      def test_keeps_node_used_by_a_flow
        write_flow_definition("orders/purchase", { "orders/validate_order" => { "valid" => nil } })
        write_node_code("orders/validate_order", "'code'")

        response = PruneNodes.call(server_context: {})

        assert_path_exists node_path("orders/validate_order")
        assert_equal "ok", response.content.first[:text]
      end

      def test_removes_empty_directories_left_behind
        write_node_code("orders/unused_node", "'code'")

        PruneNodes.call(server_context: {})

        refute File.directory?(File.join(nodes_dir, "orders"))
      end
    end
  end
end
