require "test_helper"

module SyncTraverse
  module Tools
    class RunTestsTest < SyncTraverse::TestCase
      def test_runs_nothing_in_empty_project
        response = run_tests

        refute_predicate response, :error?
        assert_match(/0 runs, 0 assertions, 0 failures, 0 errors/, response.content.first[:text])
      end

      def test_passes_when_results_match_for_every_action_of_every_flow
        write_flow(
          "orders/purchase",
          { "validate_order" => { "valid" => "charge_payment", "invalid" => nil }, "charge_payment" => { "paid" => nil } }
        )
        write_flow("orders/refund", { "validate_order" => { "valid" => nil, "invalid" => nil } })
        write_action("validate_order", %w[valid invalid])
        write_action("charge_payment", %w[paid])

        response = run_tests

        refute_predicate response, :error?
        assert_match(/3 runs, \d+ assertions, 0 failures, 0 errors/, response.content.first[:text])
      end

      def test_fails_when_flow_uses_result_not_declared_by_action
        write_flow("orders/purchase", { "validate_order" => { "valid" => nil, "invalid" => nil } })
        write_action("validate_order", %w[valid])

        response = run_tests

        assert_predicate response, :error?
        assert_match(/Result\(s\) used by the flow but not declared in .*RESULTS/, response.content.first[:text])
      end

      def test_fails_when_action_declares_result_without_transition_in_flow
        write_flow("orders/purchase", { "validate_order" => { "valid" => nil } })
        write_action("validate_order", %w[valid invalid])

        response = run_tests

        assert_predicate response, :error?
        assert_match(/Result\(s\) declared in .*RESULTS but without a transition in the flow/, response.content.first[:text])
      end

      def test_fails_when_action_does_not_declare_results
        write_flow("orders/purchase", { "validate_order" => { "valid" => nil } })
        write_action_file("validate_order", "module ValidateOrder\n  class Action\n  end\nend\n")

        response = run_tests

        assert_predicate response, :error?
        assert_match(/must define RESULTS/, response.content.first[:text])
      end

      def test_fails_with_readable_message_when_action_is_missing
        write_flow("orders/purchase", { "validate_order" => { "valid" => nil } })

        response = run_tests

        assert_predicate response, :error?
        assert_match(%r{Action validate_order not found: .*validate_order/action\.rb does not exist}, response.content.first[:text])
        refute_match(/LoadError/, response.content.first[:text])
      end

      def test_runs_every_action_test_file
        write_action_test("validate_order", passing_test("ValidateOrderTest"))
        write_action_test("validate_order", passing_test("ValidateOrderRulesTest"), file_name: "rules_test.rb")
        write_action_test("orders/charge_payment", passing_test("ChargePaymentTest"))

        response = run_tests

        refute_predicate response, :error?
        assert_match(/3 runs, \d+ assertions, 0 failures, 0 errors/, response.content.first[:text])
      end

      def test_reports_failing_action_tests
        write_action_test("validate_order", failing_test("ValidateOrderTest"))

        response = run_tests

        assert_predicate response, :error?
        assert_match(/boom/, response.content.first[:text])
      end

      def test_runs_flow_tests_through_real_actions
        write_flow("orders/purchase", { "price_order" => { "priced" => "charge_payment" }, "charge_payment" => { "paid" => nil } })
        write_context_action("price_order", :priced, "context[:total] = 100")
        write_context_action("charge_payment", :paid, "context[:charged] = context.fetch(:total)")
        write_flow_test("orders/purchase", purchase_flow_test(<<~RUBY))
          context = {}
          assert_equal :paid, SyncTraverse::Runner.call("orders/purchase", context)
          assert_equal 100, context[:charged]
        RUBY

        response = run_tests

        refute_predicate response, :error?
        assert_match(/3 runs, \d+ assertions, 0 failures, 0 errors/, response.content.first[:text])
      end

      def test_flow_test_detects_action_expecting_old_context_key
        write_flow("orders/purchase", { "price_order" => { "priced" => "charge_payment" }, "charge_payment" => { "paid" => nil } })
        write_context_action("price_order", :priced, "context[:total_cents] = 100")
        write_context_action("charge_payment", :paid, "context[:charged] = context.fetch(:total)")
        write_flow_test("orders/purchase", purchase_flow_test(<<~RUBY))
          assert_equal :paid, SyncTraverse::Runner.call("orders/purchase", {})
        RUBY

        response = run_tests

        assert_predicate response, :error?
        assert_match(/KeyError: key not found: :total/, response.content.first[:text])
      end

      def test_returns_utf8_output_regardless_of_default_external_encoding
        write_action_test("validate_order", failing_test("ValidateOrderTest", "Należy wybrać miejsce"))

        response = with_default_external(Encoding::US_ASCII) { run_tests }
        text = response.content.first[:text]

        assert_equal Encoding::UTF_8, text.encoding
        assert_includes text, "Należy wybrać miejsce"
      end

      private

      def run_tests
        RunTests.call(server_context: {})
      end

      def write_action(action_name, results)
        namespace = action_name.split("_").map(&:capitalize).join
        write_action_file(action_name, <<~RUBY)
          module #{namespace}
            class Action
              RESULTS = %i[#{results.join(" ")}].freeze
            end
          end
        RUBY
      end

      def write_context_action(action_name, result, statement)
        namespace = action_name.split("_").map(&:capitalize).join
        write_action_file(action_name, <<~RUBY)
          module #{namespace}
            class Action
              RESULTS = %i[#{result}].freeze

              def self.call(context)
                #{statement}
                :#{result}
              end
            end
          end
        RUBY
      end

      # Requires the actions itself, as the application autoloads them in a real setup.
      def purchase_flow_test(body)
        <<~RUBY
          require "minitest/autorun"
          require #{action_path("price_order").inspect}
          require #{action_path("charge_payment").inspect}

          class PurchaseFlowTest < Minitest::Test
            def test_purchase
          #{body.gsub(/^/, "    ")}
            end
          end
        RUBY
      end

      def passing_test(class_name)
        <<~RUBY
          require "minitest/autorun"

          class #{class_name} < Minitest::Test
            def test_passes
              assert true
            end
          end
        RUBY
      end

      def failing_test(class_name, message = "boom")
        <<~RUBY
          # frozen_string_literal: true

          require "minitest/autorun"

          class #{class_name} < Minitest::Test
            def test_fails
              assert false, #{message.inspect}
            end
          end
        RUBY
      end
    end
  end
end
