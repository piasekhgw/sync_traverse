require "test_helper"

module SyncTraverse
  module Tools
    class GetFlowTest < SyncTraverse::TestCase
      def test_returns_empty_graph_for_unknown_flow
        response = GetFlow.call(flow_name: "orders/purchase", server_context: {})

        refute_predicate response, :error?
        assert_equal({}, JSON.parse(response.content.first[:text]))
        assert_equal "Phase: none", response.content.last[:text]
      end

      def test_returns_existing_flow
        write_flow_stable("orders/purchase", { "validate_order" => { "valid" => nil } })

        response = GetFlow.call(flow_name: "orders/purchase", server_context: {})

        refute_predicate response, :error?
        assert_equal({ "validate_order" => { "valid" => nil } }, JSON.parse(response.content.first[:text]))
        assert_equal "Phase: stable", response.content.last[:text]
      end

      def test_returns_draft_in_draft_phase
        write_flow_stable("orders/purchase", { "validate_order" => { "valid" => nil } })
        write_flow_draft("orders/purchase", { "validate_order" => { "valid" => "charge_payment" }, "charge_payment" => {} })

        response = GetFlow.call(flow_name: "orders/purchase", server_context: {})

        assert_equal "charge_payment", JSON.parse(response.content.first[:text])["validate_order"]["valid"]
        assert_equal "Phase: draft", response.content.last[:text]
      end

      def test_returns_approved_flow_in_approved_phase
        write_flow_stable("orders/purchase", { "old" => { "valid" => nil } })
        write_flow_approved("orders/purchase", { "validate_order" => { "valid" => nil } })

        response = GetFlow.call(flow_name: "orders/purchase", server_context: {})

        assert_equal({ "validate_order" => { "valid" => nil } }, JSON.parse(response.content.first[:text]))
        assert_equal "Phase: approved", response.content.last[:text]
      end

      def test_rejects_invalid_flow_name
        response = GetFlow.call(flow_name: "../escape", server_context: {})

        assert_predicate response, :error?
        assert_equal "Invalid name(s): ../escape", response.content.first[:text]
      end
    end
  end
end
