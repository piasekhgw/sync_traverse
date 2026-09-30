require "test_helper"

module GraphFlow
  class RunnerTest < GraphFlow::TestCase
    def test_runs_flow_following_outcomes_until_terminal_node
      write_flow_definition(
        "orders/purchase",
        {
          "orders/validate_order" => { "valid" => "orders/charge_payment", "invalid" => nil },
          "orders/charge_payment" => { "paid" => nil }
        }
      )
      write_node_code("orders/validate_order", <<~RUBY)
        module Orders
          class ValidateOrder
            def self.call(context)
              context[:steps] << :validate_order
              :valid
            end
          end
        end
      RUBY
      write_node_code("orders/charge_payment", <<~RUBY)
        module Orders
          class ChargePayment
            def self.call(context)
              context[:steps] << :charge_payment
              :paid
            end
          end
        end
      RUBY

      context = Runner.call("orders/purchase", steps: [])

      assert_equal %i[validate_order charge_payment], context[:steps]
    end
  end
end
