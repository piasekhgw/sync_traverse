require "test_helper"

module SyncTraverse
  class FlowTest < Minitest::Test
    def test_to_h_puts_start_action_first
      flow = Flow.new
      flow.add_transitions([{ source: "B", target: "C", source_result: "ok" }])
      flow.add_transitions([{ source: "A", target: "B", source_result: "ok" }])

      assert_equal %w[A B C], flow.to_h.keys
    end

    def test_to_h_keeps_order_of_other_actions
      flow = Flow.new
      flow.add_transitions(
        [
          { source: "C", target: "D", source_result: "ok" },
          { source: "B", target: "C", source_result: "ok" },
          { source: "A", target: "B", source_result: "ok" }
        ]
      )

      assert_equal %w[A C D B], flow.to_h.keys
    end

    def test_to_h_does_not_change_definition
      flow = Flow.new
      flow.add_transitions([{ source: "B", target: "C", source_result: "ok" }])
      flow.add_transitions([{ source: "A", target: "B", source_result: "ok" }])
      flow.to_h

      flow.add_transitions([{ source: "C", target: nil, source_result: "ok" }])

      assert_equal({ "ok" => nil }, flow.to_h["C"])
    end
  end
end
