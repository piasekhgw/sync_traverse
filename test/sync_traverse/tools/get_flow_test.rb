require "test_helper"

module SyncTraverse
  module Tools
    class GetFlowTest < SyncTraverse::TestCase
      def test_returns_empty_graph_for_unknown_flow
        response = GetFlow.call(flow_name: "orders/purchase", server_context: {})

        refute_predicate response, :error?
        assert_equal({ "phase" => "none", "graph" => {}, "flow_tests" => {} }, flow_json(response))
      end

      def test_returns_existing_flow
        write_flow_stable("orders/purchase", { "validate_order" => { "valid" => nil } })

        response = GetFlow.call(flow_name: "orders/purchase", server_context: {})

        refute_predicate response, :error?
        assert_equal({ "validate_order" => { "valid" => nil } }, flow_json(response)["graph"])
        assert_equal "stable", flow_json(response)["phase"]
      end

      def test_returns_draft_in_draft_phase
        write_flow_stable("orders/purchase", { "validate_order" => { "valid" => nil } })
        write_flow_draft("orders/purchase", { "validate_order" => { "valid" => "charge_payment" }, "charge_payment" => {} })

        response = GetFlow.call(flow_name: "orders/purchase", server_context: {})

        assert_equal "charge_payment", flow_json(response)["graph"]["validate_order"]["valid"]
        assert_equal "draft", flow_json(response)["phase"]
      end

      def test_returns_approved_flow_in_approved_phase
        write_flow_stable("orders/purchase", { "old" => { "valid" => nil } })
        write_flow_approved("orders/purchase", { "validate_order" => { "valid" => nil } })

        response = GetFlow.call(flow_name: "orders/purchase", server_context: {})

        assert_equal({ "validate_order" => { "valid" => nil } }, flow_json(response)["graph"])
        assert_equal "approved", flow_json(response)["phase"]
      end

      def test_returns_flow_tests_of_the_flow
        write_flow_stable("orders/purchase", { "validate_order" => { "valid" => nil } })
        write_flow_test("orders/purchase", "'test'")
        write_flow_test("orders/purchase", "'paths'", file_name: "paths_test.rb")
        write_flow_test("orders/refund", "'other'")

        response = GetFlow.call(flow_name: "orders/purchase", server_context: {})

        assert_equal({ "paths_test.rb" => "'paths'", "test.rb" => "'test'" }, flow_json(response)["flow_tests"])
      end

      def test_returns_empty_flow_tests_without_tests
        write_flow_stable("orders/purchase", { "validate_order" => { "valid" => nil } })

        response = GetFlow.call(flow_name: "orders/purchase", server_context: {})

        assert_equal({}, flow_json(response)["flow_tests"])
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
