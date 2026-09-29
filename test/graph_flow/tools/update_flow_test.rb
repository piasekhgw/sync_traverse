require "test_helper"

module GraphFlow
  module Tools
    class UpdateFlowTest < GraphFlow::TestCase
      def test_adds_edges_and_creates_referenced_nodes
        response = UpdateFlow.call(
          flow_name: "orders/purchase",
          add_edges: [
            { source: "validate_order", target: "charge_payment", source_outcome: "valid" },
            { source: "validate_order", target: nil, source_outcome: "invalid" },
            { source: "charge_payment", target: nil, source_outcome: "paid" }
          ],
          server_context: {}
        )

        refute response.error?
        assert_equal "ok", response.content.first[:text]
        assert_equal(
          {
            "validate_order" => { "valid" => "charge_payment", "invalid" => nil },
            "charge_payment" => { "paid" => nil }
          },
          JSON.parse(File.read(flow_definition_path("orders/purchase")))
        )
      end

      def test_removes_edges_before_adding
        write_flow_definition("orders/purchase", { "a" => { "old" => "b" }, "b" => {} })

        response = UpdateFlow.call(
          flow_name: "orders/purchase",
          remove_edges: [{ source: "a", target: "b", source_outcome: "old" }],
          add_edges: [{ source: "a", target: nil, source_outcome: "old" }],
          server_context: {}
        )

        refute response.error?
        assert_equal({ "a" => { "old" => nil } }, JSON.parse(File.read(flow_definition_path("orders/purchase"))))
      end

      def test_rejects_cycle_without_saving
        response = UpdateFlow.call(
          flow_name: "orders/purchase",
          add_edges: [
            { source: "a", target: "b", source_outcome: "ok" },
            { source: "b", target: "a", source_outcome: "back" }
          ],
          server_context: {}
        )

        assert response.error?
        assert_equal(
          "Flow must be acyclic\nFlow must have exactly one source node, found: none",
          response.content.first[:text]
        )
        refute File.exist?(flow_definition_path("orders/purchase"))
      end

      def test_rejects_conflicting_outcome_target
        write_flow_definition("orders/purchase", { "a" => { "ok" => "b" }, "b" => {} })

        response = UpdateFlow.call(
          flow_name: "orders/purchase",
          add_edges: [{ source: "a", target: "c", source_outcome: "ok" }],
          server_context: {}
        )

        assert response.error?
        assert_equal(
          "Outcome 'ok' of node 'a' already targets 'b'; remove that edge first",
          response.content.first[:text]
        )
      end

      def test_rejects_invalid_node_name
        response = UpdateFlow.call(
          flow_name: "orders/purchase",
          add_edges: [{ source: "../escape", target: nil, source_outcome: "ok" }],
          server_context: {}
        )

        assert response.error?
        assert_equal "Invalid name(s): ../escape", response.content.first[:text]
      end
    end
  end
end
