require "test_helper"

module SyncTraverse
  class RunnerTest < SyncTraverse::TestCase
    def test_runs_flow_following_outcomes_until_terminal_node
      write_flow_stable(
        "orders/purchase",
        {
          "orders/validate_order" => { "valid" => "orders/charge_payment", "invalid" => nil },
          "orders/charge_payment" => { "paid" => nil }
        }
      )
      write_node_code("orders/validate_order", <<~RUBY)
        module Orders
          module ValidateOrder
            class Node
              def self.call(context)
                context[:steps] << :validate_order
                :valid
              end
            end
          end
        end
      RUBY
      write_node_code("orders/charge_payment", <<~RUBY)
        module Orders
          module ChargePayment
            class Node
              def self.call(context)
                context[:steps] << :charge_payment
                :paid
              end
            end
          end
        end
      RUBY

      context = { steps: [] }

      assert_equal "paid", Runner.call("orders/purchase", context)
      assert_equal %i[validate_order charge_payment], context[:steps]
    end
  end
end
