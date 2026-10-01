require "test_helper"

module SyncBraid
  module Tools
    class GetNodeCodeTest < SyncBraid::TestCase
      def test_returns_nil_for_missing_node
        response = GetNodeCode.call(node: "orders/validate_order", server_context: {})

        refute_predicate response, :error?
        assert_nil JSON.parse(response.content.first[:text])
      end

      def test_returns_existing_node_code
        write_node_code("orders/validate_order", "module Orders\nend\n")

        response = GetNodeCode.call(node: "orders/validate_order", server_context: {})

        refute_predicate response, :error?
        assert_equal "module Orders\nend\n", JSON.parse(response.content.first[:text])
      end

      def test_rejects_invalid_node_name
        response = GetNodeCode.call(node: "../escape", server_context: {})

        assert_predicate response, :error?
        assert_equal "Invalid name(s): ../escape", response.content.first[:text]
      end
    end
  end
end
