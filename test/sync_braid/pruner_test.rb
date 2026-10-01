require "test_helper"

module SyncBraid
  class PrunerTest < SyncBraid::TestCase
    def test_removes_empty_flow_definition
      write_flow_definition("orders/purchase", {})

      Pruner.new.call

      refute_path_exists flow_definition_path("orders/purchase")
    end

    def test_keeps_non_empty_flow_definition
      write_flow_definition("orders/purchase", { "a" => {} })

      Pruner.new.call

      assert_path_exists flow_definition_path("orders/purchase")
    end

    def test_removes_node_unused_by_any_flow
      write_node_code("orders/unused_node", "'code'")

      Pruner.new.call

      refute_path_exists node_path("orders/unused_node")
    end

    def test_keeps_node_used_by_a_flow
      write_flow_definition("orders/purchase", { "orders/validate_order" => { "valid" => nil } })
      write_node_code("orders/validate_order", "'code'")

      Pruner.new.call

      assert_path_exists node_path("orders/validate_order")
    end

    def test_removes_empty_directories_left_behind
      write_node_code("orders/unused_node", "'code'")

      Pruner.new.call

      refute File.directory?(File.join(nodes_dir, "orders"))
    end
  end
end
