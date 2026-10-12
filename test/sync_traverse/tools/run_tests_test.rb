require "test_helper"

module SyncTraverse
  module Tools
    class RunTestsTest < SyncTraverse::TestCase
      def test_rejects_invalid_names
        response = run_tests(actions: ["../escape"], flows: ["bad flow"])

        assert_predicate response, :error?
        assert_equal "Invalid name(s): bad flow, ../escape", response.content.first[:text]
      end

      def test_runs_nothing_without_actions_and_flows
        response = run_tests

        refute_predicate response, :error?
        assert_match(/0 runs, 0 assertions, 0 failures, 0 errors/, response.content.first[:text])
      end

      def test_errors_when_flow_not_found
        response = run_tests(flows: ["orders/purchase"])

        assert_predicate response, :error?
        assert_equal "Flow not found: orders/purchase", response.content.first[:text]
      end

      def test_errors_when_no_tests_found_for_action
        write_action_file("validate_order", "'code'")

        response = run_tests(actions: ["validate_order"])

        assert_predicate response, :error?
        assert_equal "No tests found for action: validate_order", response.content.first[:text]
      end

      def test_runs_flow_test_passing_when_results_match_for_every_action
        write_flow_stable(
          "orders/purchase",
          { "validate_order" => { "valid" => "charge_payment", "invalid" => nil }, "charge_payment" => { "paid" => nil } }
        )
        write_action("validate_order", %w[valid invalid])
        write_action("charge_payment", %w[paid])

        response = run_tests(flows: ["orders/purchase"])

        refute_predicate response, :error?
        assert_match(/2 runs, \d+ assertions, 0 failures, 0 errors/, response.content.first[:text])
      end

      def test_flow_test_uses_draft_instead_of_stable_flow
        write_flow_stable("orders/purchase", { "validate_order" => { "valid" => nil } })
        write_flow_draft("orders/purchase", { "validate_order" => { "valid" => nil, "invalid" => nil } })
        write_action("validate_order", %w[valid invalid])

        response = run_tests(flows: ["orders/purchase"])

        refute_predicate response, :error?
        assert_match(/1 runs, \d+ assertions, 0 failures, 0 errors/, response.content.first[:text])
      end

      def test_flow_test_uses_approved_flow_instead_of_stable_flow
        write_flow_stable("orders/purchase", { "validate_order" => { "valid" => nil } })
        write_flow_approved("orders/purchase", { "validate_order" => { "valid" => nil, "invalid" => nil } })
        write_action("validate_order", %w[valid invalid])

        response = run_tests(flows: ["orders/purchase"])

        refute_predicate response, :error?
        assert_match(/1 runs, \d+ assertions, 0 failures, 0 errors/, response.content.first[:text])
      end

      def test_flow_test_does_not_run_action_tests_that_were_not_requested
        write_flow_stable("orders/purchase", { "validate_order" => { "valid" => nil } })
        write_action("validate_order", %w[valid])
        write_action_test("validate_order", failing_test("ValidateOrderTest"))

        response = run_tests(flows: ["orders/purchase"])

        refute_predicate response, :error?
        assert_match(/1 runs, \d+ assertions, 0 failures, 0 errors/, response.content.first[:text])
      end

      def test_fails_when_flow_uses_result_not_declared_by_action
        write_flow_stable("orders/purchase", { "validate_order" => { "valid" => nil, "invalid" => nil } })
        write_action("validate_order", %w[valid])

        response = run_tests(flows: ["orders/purchase"])

        assert_predicate response, :error?
        assert_match(/Result\(s\) used by the flow but not declared in .*RESULTS/, response.content.first[:text])
      end

      def test_fails_when_action_declares_result_without_transition_in_flow
        write_flow_stable("orders/purchase", { "validate_order" => { "valid" => nil } })
        write_action("validate_order", %w[valid invalid])

        response = run_tests(flows: ["orders/purchase"])

        assert_predicate response, :error?
        assert_match(/Result\(s\) declared in .*RESULTS but without a transition in the flow/, response.content.first[:text])
      end

      def test_fails_when_action_does_not_declare_results
        write_flow_stable("orders/purchase", { "validate_order" => { "valid" => nil } })
        write_action_file("validate_order", "module ValidateOrder\n  class Action\n  end\nend\n")

        response = run_tests(flows: ["orders/purchase"])

        assert_predicate response, :error?
        assert_match(/must define RESULTS/, response.content.first[:text])
      end

      def test_fails_when_action_file_is_missing
        write_flow_stable("orders/purchase", { "validate_order" => { "valid" => nil } })

        response = run_tests(flows: ["orders/purchase"])

        assert_predicate response, :error?
        assert_match(%r{cannot load such file.*validate_order/action}, response.content.first[:text])
      end

      def test_runs_only_tests_of_the_given_actions
        write_action_test("validate_order", passing_test("ValidateOrderTest"))
        write_action_test("unrelated_action", failing_test("UnrelatedActionTest"))

        response = run_tests(actions: ["validate_order"])

        refute_predicate response, :error?
        assert_match(/1 runs, \d+ assertions, 0 failures, 0 errors/, response.content.first[:text])
      end

      def test_runs_every_test_file_of_every_given_action
        write_action_test("validate_order", passing_test("ValidateOrderTest"))
        write_action_test("validate_order", passing_test("ValidateOrderRulesTest"), file_name: "rules_test.rb")
        write_action_test("charge_payment", passing_test("ChargePaymentTest"))

        response = run_tests(actions: %w[validate_order charge_payment])

        refute_predicate response, :error?
        assert_match(/3 runs, \d+ assertions, 0 failures, 0 errors/, response.content.first[:text])
      end

      def test_runs_action_tests_and_flow_tests_together
        write_flow_stable("orders/purchase", { "validate_order" => { "valid" => nil } })
        write_action("validate_order", %w[valid])
        write_action_test("validate_order", passing_test("ValidateOrderTest"))

        response = run_tests(actions: ["validate_order"], flows: ["orders/purchase"])

        refute_predicate response, :error?
        assert_match(/2 runs, \d+ assertions, 0 failures, 0 errors/, response.content.first[:text])
      end

      def test_reports_failing_action_tests
        write_action_test("validate_order", failing_test("ValidateOrderTest"))

        response = run_tests(actions: ["validate_order"])

        assert_predicate response, :error?
        assert_match(/boom/, response.content.first[:text])
      end

      def test_returns_utf8_output_regardless_of_default_external_encoding
        write_action_test("validate_order", failing_test("ValidateOrderTest", "Należy wybrać miejsce"))

        response = with_default_external(Encoding::US_ASCII) do
          run_tests(actions: ["validate_order"])
        end
        text = response.content.first[:text]

        assert_equal Encoding::UTF_8, text.encoding
        assert_includes text, "Należy wybrać miejsce"
      end

      private

      def run_tests(actions: [], flows: [])
        RunTests.call(actions: actions, flows: flows, server_context: {})
      end

      def with_default_external(encoding)
        original = Encoding.default_external
        Encoding.default_external = encoding
        yield
      ensure
        Encoding.default_external = original
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
