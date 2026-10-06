require "test_helper"

module SyncTraverse
  module Tools
    class GetNodeCodeTest < SyncTraverse::TestCase
      def test_returns_empty_object_for_missing_node
        response = GetNodeCode.call(node: "orders/validate_order", server_context: {})

        refute_predicate response, :error?
        assert_empty JSON.parse(response.content.first[:text])
      end

      def test_returns_existing_node_code
        write_node_code("orders/validate_order", "module Orders\nend\n")

        response = GetNodeCode.call(node: "orders/validate_order", server_context: {})

        refute_predicate response, :error?
        assert_equal({ "node.rb" => "module Orders\nend\n" }, JSON.parse(response.content.first[:text]))
      end

      def test_returns_local_files_and_tests_of_node
        write_node_code("orders/validate_order", "'node'")
        write_node_file("orders/validate_order", "'local'", file_name: "order.rb")
        write_node_test("orders/validate_order", "'test'")
        write_node_code("orders/other_node", "'other'")

        response = GetNodeCode.call(node: "orders/validate_order", server_context: {})

        assert_equal(
          {
            "node.rb" => "'node'",
            "order.rb" => "'local'",
            "test.rb" => "'test'"
          },
          JSON.parse(response.content.first[:text])
        )
      end

      def test_returns_files_of_other_types
        write_node_code("orders/validate_order", "'node'")
        write_node_test("orders/validate_order", "{}", file_name: "schema.json")

        response = GetNodeCode.call(node: "orders/validate_order", server_context: {})

        assert_equal %w[node.rb schema.json], JSON.parse(response.content.first[:text]).keys
      end

      def test_rejects_invalid_node_name
        response = GetNodeCode.call(node: "../escape", server_context: {})

        assert_predicate response, :error?
        assert_equal "Invalid name(s): ../escape", response.content.first[:text]
      end
    end
  end
end
