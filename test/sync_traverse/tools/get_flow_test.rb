require "test_helper"

module SyncTraverse
  module Tools
    class GetFlowTest < SyncTraverse::TestCase
      def test_returns_empty_definition_for_unknown_flow
        response = GetFlow.call(flow_name: "orders/purchase", server_context: {})

        refute_predicate response, :error?
        assert_equal({ "definition" => {}, "test_files" => {} }, flow_json(response))
      end

      def test_reports_corrupted_flow_file
        write_code_file(flow_definition_path("orders/purchase"), "{ \"validate_order\": ")

        response = GetFlow.call(flow_name: "orders/purchase", server_context: {})

        assert_predicate response, :error?
        assert_match(/definition\.json is not valid JSON/, response.content.first[:text])
      end

      def test_returns_definition_with_start_action_first
        write_flow("orders/purchase", { "charge_payment" => { "paid" => nil }, "validate_order" => { "valid" => "charge_payment" } })

        response = GetFlow.call(flow_name: "orders/purchase", server_context: {})

        refute_predicate response, :error?
        assert_equal %w[validate_order charge_payment], flow_json(response)["definition"].keys
      end

      def test_returns_flow_tests_of_the_flow
        write_flow("orders/purchase", { "validate_order" => { "valid" => nil } })
        write_flow_test("orders/purchase", "'test'")
        write_flow_test("orders/purchase", "'paths'", file_name: "paths_test.rb")
        write_flow_test("orders/refund", "'other'")

        response = GetFlow.call(flow_name: "orders/purchase", server_context: {})

        assert_equal({ "paths_test.rb" => "'paths'", "test.rb" => "'test'" }, flow_json(response)["test_files"])
      end

      def test_returns_helper_files
        write_flow("orders/purchase", { "validate_order" => { "valid" => nil } })
        write_flow_test("orders/purchase", "{}", file_name: "fixture.json")

        response = GetFlow.call(flow_name: "orders/purchase", server_context: {})

        assert_equal({ "fixture.json" => "{}" }, flow_json(response)["test_files"])
      end

      def test_returns_utf8_flow_tests_when_server_locale_is_not_utf8
        write_flow("orders/purchase", { "validate_order" => { "valid" => nil } })
        write_flow_test("orders/purchase", "# Zamówienie musi być zapłacone\n")

        response = with_default_external(Encoding::US_ASCII) do
          GetFlow.call(flow_name: "orders/purchase", server_context: {})
        end

        refute_predicate response, :error?
        assert_equal({ "test.rb" => "# Zamówienie musi być zapłacone\n" }, flow_json(response)["test_files"])
      end

      def test_returns_empty_flow_tests_without_tests
        write_flow("orders/purchase", { "validate_order" => { "valid" => nil } })

        response = GetFlow.call(flow_name: "orders/purchase", server_context: {})

        assert_equal({}, flow_json(response)["test_files"])
      end

      def test_rejects_invalid_flow_name
        response = GetFlow.call(flow_name: "../escape", server_context: {})

        assert_predicate response, :error?
        assert_equal "Invalid name(s): ../escape", response.content.first[:text]
      end

      private

      def flow_json(response)
        JSON.parse(response.content.first[:text])
      end
    end
  end
end
