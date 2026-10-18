require "test_helper"

module SyncTraverse
  class FlowTest < Minitest::Test
    def test_to_h_puts_start_action_first_and_keeps_order_of_other_actions
      flow = Flow.new(
        "C" => { "ok" => "D" },
        "B" => { "ok" => "C" },
        "D" => { "ok" => nil },
        "A" => { "ok" => "B" }
      )

      assert_equal %w[A C B D], flow.to_h.keys
    end

    def test_to_mermaid_labels_transitions_and_gives_every_end_its_own_node
      flow = Flow.new(
        "orders/validate_order" => { "valid" => "orders/charge_payment", "invalid" => nil },
        "orders/charge_payment" => { "paid" => nil }
      )

      assert_equal <<~MERMAID, flow.to_mermaid
        flowchart TD
          orders/validate_order[orders/validate_order]
          orders/charge_payment[orders/charge_payment]
          orders/validate_order -->|valid| orders/charge_payment
          orders/validate_order -->|invalid| end1((End))
          orders/charge_payment -->|paid| end2((End))
      MERMAID
    end
  end
end
