require "test_helper"

module SyncTraverse
  module Tools
    class GetActionCodeTest < SyncTraverse::TestCase
      def test_returns_empty_object_for_missing_action
        response = GetActionCode.call(action: "orders/validate_order", server_context: {})

        refute_predicate response, :error?
        assert_empty JSON.parse(response.content.first[:text])
      end

      def test_returns_existing_action_code
        write_action_code("orders/validate_order", "module Orders\nend\n")

        response = GetActionCode.call(action: "orders/validate_order", server_context: {})

        refute_predicate response, :error?
        assert_equal({ "action.rb" => "module Orders\nend\n" }, JSON.parse(response.content.first[:text]))
      end

      def test_returns_utf8_code_when_server_locale_is_not_utf8
        write_action_code("orders/validate_order", "# Zamówienie musi być zapłacone\n")

        response = with_default_external(Encoding::US_ASCII) do
          GetActionCode.call(action: "orders/validate_order", server_context: {})
        end

        refute_predicate response, :error?
        assert_equal({ "action.rb" => "# Zamówienie musi być zapłacone\n" }, JSON.parse(response.content.first[:text]))
      end

      def test_returns_local_files_and_tests_of_action
        write_action_code("orders/validate_order", "'action'")
        write_action_file("orders/validate_order", "'local'", file_name: "order.rb")
        write_action_test("orders/validate_order", "'test'")
        write_action_code("orders/other_action", "'other'")

        response = GetActionCode.call(action: "orders/validate_order", server_context: {})

        assert_equal(
          {
            "action.rb" => "'action'",
            "order.rb" => "'local'",
            "test.rb" => "'test'"
          },
          JSON.parse(response.content.first[:text])
        )
      end

      def test_returns_files_of_other_types
        write_action_code("orders/validate_order", "'action'")
        write_action_file("orders/validate_order", "{}", file_name: "schema.json")

        response = GetActionCode.call(action: "orders/validate_order", server_context: {})

        assert_equal %w[action.rb schema.json], JSON.parse(response.content.first[:text]).keys
      end

      def test_rejects_invalid_action_name
        response = GetActionCode.call(action: "../escape", server_context: {})

        assert_predicate response, :error?
        assert_equal "Invalid name(s): ../escape", response.content.first[:text]
      end
    end
  end
end
