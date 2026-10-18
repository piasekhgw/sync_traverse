require "test_helper"

module SyncTraverse
  module Tools
    class GetActionTest < SyncTraverse::TestCase
      def test_returns_empty_files_for_missing_action
        response = GetAction.call(action: "orders/validate_order", server_context: {})

        refute_predicate response, :error?
        assert_equal({ "files" => {}, "test_files" => {} }, JSON.parse(response.content.first[:text]))
      end

      def test_returns_existing_action_code
        write_action_code("orders/validate_order", "module Orders\nend\n")

        response = GetAction.call(action: "orders/validate_order", server_context: {})

        refute_predicate response, :error?
        assert_equal({ "action.rb" => "module Orders\nend\n" }, JSON.parse(response.content.first[:text])["files"])
      end

      def test_returns_utf8_code_when_server_locale_is_not_utf8
        write_action_code("orders/validate_order", "# Zamówienie musi być zapłacone\n")

        response = with_default_external(Encoding::US_ASCII) do
          GetAction.call(action: "orders/validate_order", server_context: {})
        end

        refute_predicate response, :error?
        assert_equal({ "action.rb" => "# Zamówienie musi być zapłacone\n" }, JSON.parse(response.content.first[:text])["files"])
      end

      def test_returns_local_files_and_tests_of_action
        write_action_code("orders/validate_order", "'action'")
        write_action_file("orders/validate_order", "'local'", file_name: "order.rb")
        write_action_test("orders/validate_order", "'test'")
        write_action_test("orders/validate_order", "{}", file_name: "fixture.json")
        write_action_code("orders/other_action", "'other'")

        response = GetAction.call(action: "orders/validate_order", server_context: {})

        assert_equal(
          {
            "files" => { "action.rb" => "'action'", "order.rb" => "'local'" },
            "test_files" => { "fixture.json" => "{}", "test.rb" => "'test'" }
          },
          JSON.parse(response.content.first[:text])
        )
      end

      def test_returns_files_of_other_types
        write_action_code("orders/validate_order", "'action'")
        write_action_file("orders/validate_order", "{}", file_name: "schema.json")

        response = GetAction.call(action: "orders/validate_order", server_context: {})

        assert_equal %w[action.rb schema.json], JSON.parse(response.content.first[:text])["files"].keys
      end

      def test_rejects_invalid_action_name
        response = GetAction.call(action: "../escape", server_context: {})

        assert_predicate response, :error?
        assert_equal "Invalid name(s): ../escape", response.content.first[:text]
      end
    end
  end
end
