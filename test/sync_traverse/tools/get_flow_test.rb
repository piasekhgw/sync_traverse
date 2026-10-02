require "test_helper"

module SyncTraverse
  module Tools
    class GetFlowTest < SyncTraverse::TestCase
      def test_returns_empty_definition_for_unknown_flow
        response = GetFlow.call(flow_name: "orders/purchase", server_context: {})

        refute_predicate response, :error?
        assert_equal({}, JSON.parse(response.content.first[:text]))
      end

      def test_returns_existing_flow_definition
        write_flow_definition("orders/purchase", { "validate_order" => { "valid" => nil } })

        response = GetFlow.call(flow_name: "orders/purchase", server_context: {})

        refute_predicate response, :error?
        assert_equal({ "validate_order" => { "valid" => nil } }, JSON.parse(response.content.first[:text]))
      end

      def test_rejects_invalid_flow_name
        response = GetFlow.call(flow_name: "../escape", server_context: {})

        assert_predicate response, :error?
        assert_equal "Invalid name(s): ../escape", response.content.first[:text]
      end
    end
  end
end
