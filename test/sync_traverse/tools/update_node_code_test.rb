require "test_helper"

module SyncTraverse
  module Tools
    class UpdateNodeCodeTest < SyncTraverse::TestCase
      def test_creates_node_file
        response = update("orders/validate_order", "node.rb" => "module Orders\nend\n")

        refute_predicate response, :error?
        assert_equal "Success", response.content.first[:text]
        assert_equal "module Orders\nend\n", File.read(node_path("orders/validate_order"))
      end

      def test_writes_multiple_files_in_one_call
        update(
          "orders/validate_order",
          "node.rb" => "'node'",
          "order.rb" => "'local'",
          "test.rb" => "'test'"
        )

        assert_equal "'node'", File.read(node_path("orders/validate_order"))
        assert_equal "'local'", File.read(node_path("orders/validate_order", "order.rb"))
        assert_equal "'test'", File.read(node_test_path("orders/validate_order"))
      end

      def test_stores_test_files_outside_node_directory
        update("orders/validate_order", "node.rb" => "'node'", "test.rb" => "'test'", "rules_test.rb" => "'rules'")

        assert_equal %w[node.rb], Dir.children(File.join(nodes_dir, "orders/validate_order"))
        assert_equal %w[rules_test.rb test.rb], Dir.children(File.join(tests_dir, "orders/validate_order")).sort
      end

      def test_replaces_existing_file_and_keeps_unlisted_files
        write_node_code("orders/validate_order", "'old code'")
        write_node_test("orders/validate_order", "'test'")

        update("orders/validate_order", "node.rb" => "'new code'")

        assert_equal "'new code'", File.read(node_path("orders/validate_order"))
        assert_equal "'test'", File.read(node_test_path("orders/validate_order"))
      end

      def test_null_deletes_file
        write_node_code("orders/validate_order", "'code'")
        write_node_test("orders/validate_order", "'test'")

        update("orders/validate_order", "test.rb" => nil)

        refute_path_exists node_test_path("orders/validate_order")
        assert_path_exists node_path("orders/validate_order")
      end

      def test_rejects_update_that_leaves_node_without_node_file
        response = update("orders/validate_order", "order.rb" => "'local'")

        assert_predicate response, :error?
        assert_equal "Node file node.rb must exist", response.content.first[:text]
        refute_path_exists node_path("orders/validate_order", "order.rb")
      end

      def test_rejects_deleting_node_file_while_writing_other_files
        write_node_code("orders/validate_order", "'code'")

        response = update("orders/validate_order", "node.rb" => nil, "order.rb" => "'local'")

        assert_predicate response, :error?
        assert_path_exists node_path("orders/validate_order")
      end

      def test_writes_files_of_other_types
        update(
          "orders/validate_order",
          "node.rb" => "'node'",
          "schema.json" => "{}"
        )

        assert_equal "{}", File.read(node_path("orders/validate_order", "schema.json"))
      end

      def test_rejects_nested_files_in_node_directory
        response = update("orders/validate_order", "node.rb" => "'node'", "fixtures/order.yml" => "id: 1")

        assert_predicate response, :error?
        assert_equal "Invalid file name(s): fixtures/order.yml", response.content.first[:text]
        refute_path_exists node_path("orders/validate_order")
      end

      def test_deletes_whole_node_when_no_files_remain
        write_node_code("orders/validate_order", "'code'")
        write_node_test("orders/validate_order", "'test'")
        write_node_file("orders/validate_order", "{}", file_name: "schema.json")

        response = update(
          "orders/validate_order",
          "node.rb" => nil,
          "test.rb" => nil,
          "schema.json" => nil
        )

        assert_equal "Success", response.content.first[:text]
        assert_empty Dir.children(nodes_dir)
        assert_empty Dir.children(tests_dir)
      end

      def test_deleting_only_some_files_never_deletes_the_node
        write_node_code("orders/validate_order", "'code'")
        write_node_test("orders/validate_order", "'test'")

        response = update("orders/validate_order", "test.rb" => nil)

        assert_equal "Success", response.content.first[:text]
        assert_path_exists node_path("orders/validate_order")
      end

      def test_rejects_deleting_node_used_by_a_flow
        write_flow_stable("orders/purchase", { "orders/validate_order" => { "valid" => nil } })
        write_flow_stable("orders/refund", { "orders/validate_order" => { "valid" => nil } })
        write_node_code("orders/validate_order", "'code'")

        response = update("orders/validate_order", "node.rb" => nil)

        assert_predicate response, :error?
        assert_equal "Cannot delete node orders/validate_order, it is used by flow(s): orders/purchase, orders/refund", response.content.first[:text]
        assert_path_exists node_path("orders/validate_order")
      end

      def test_rejects_deleting_node_used_only_by_a_flow_draft
        write_flow_draft("orders/purchase", { "orders/validate_order" => { "valid" => nil } })
        write_node_code("orders/validate_order", "'code'")

        response = update("orders/validate_order", "node.rb" => nil)

        assert_predicate response, :error?
        assert_equal "Cannot delete node orders/validate_order, it is used by flow(s): orders/purchase", response.content.first[:text]
      end

      def test_rejects_deleting_node_used_only_by_an_approved_flow
        write_flow_approved("orders/purchase", { "orders/validate_order" => { "valid" => nil } })
        write_node_code("orders/validate_order", "'code'")

        response = update("orders/validate_order", "node.rb" => nil)

        assert_predicate response, :error?
        assert_equal "Cannot delete node orders/validate_order, it is used by flow(s): orders/purchase", response.content.first[:text]
      end

      def test_cannot_write_outside_node_directory
        response = update("orders/validate_order", "node.rb" => "'code'", "../other.rb" => "'x'")

        assert_predicate response, :error?
        assert_equal "Invalid file name(s): ../other.rb", response.content.first[:text]
        refute_path_exists node_path("orders/validate_order")
      end

      def test_rejects_invalid_file_names
        response = update("orders/validate_order", "../../escape.rb" => "'x'", "/abs.rb" => "'x'", "data" => "{}")

        assert_predicate response, :error?
        assert_equal "Invalid file name(s): ../../escape.rb, /abs.rb, data", response.content.first[:text]
      end

      def test_rejects_invalid_node_name
        response = update("../escape", "node.rb" => "'code'")

        assert_predicate response, :error?
        assert_equal "Invalid name(s): ../escape", response.content.first[:text]
      end

      private

      def update(node, files)
        UpdateNodeCode.call(node: node, files: files, server_context: {})
      end
    end
  end
end
