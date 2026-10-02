require "test_helper"

module SyncTraverse
  module Tools
    class UpdateNodeCodeTest < SyncTraverse::TestCase
      def test_creates_node_file
        response = UpdateNodeCode.call(node: "orders/validate_order", code: "module Orders\nend\n", server_context: {})

        refute_predicate response, :error?
        assert_equal "ok", response.content.first[:text]
        assert_equal "module Orders\nend\n", File.read(node_path("orders/validate_order"))
      end

      def test_replaces_existing_node_file
        write_node_code("orders/validate_order", "'old code'")

        UpdateNodeCode.call(node: "orders/validate_order", code: "'new code'", server_context: {})

        assert_equal "'new code'", File.read(node_path("orders/validate_order"))
      end

      def test_rejects_invalid_node_name
        response = UpdateNodeCode.call(node: "../escape", code: "'code'", server_context: {})

        assert_predicate response, :error?
        assert_equal "Invalid name(s): ../escape", response.content.first[:text]
      end
    end
  end
end
