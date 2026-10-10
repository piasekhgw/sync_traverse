require "test_helper"

module SyncTraverse
  module Tools
    class RunTestsTest < SyncTraverse::TestCase
      def test_rejects_invalid_names
        response = run_tests(nodes: ["../escape"], flows: ["bad flow"])

        assert_predicate response, :error?
        assert_equal "Invalid name(s): bad flow, ../escape", response.content.first[:text]
      end

      def test_runs_nothing_without_nodes_and_flows
        response = run_tests

        refute_predicate response, :error?
        assert_match(/0 runs, 0 assertions, 0 failures, 0 errors/, response.content.first[:text])
      end

      def test_errors_when_flow_not_found
        response = run_tests(flows: ["orders/purchase"])

        assert_predicate response, :error?
        assert_equal "Flow not found: orders/purchase", response.content.first[:text]
      end

      def test_errors_when_no_tests_found_for_node
        write_node_file("validate_order", "'code'")

        response = run_tests(nodes: ["validate_order"])

        assert_predicate response, :error?
        assert_equal "No tests found for node: validate_order", response.content.first[:text]
      end

      def test_runs_flow_test_passing_when_outcomes_match_for_every_node
        write_flow_definition(
          "orders/purchase",
          { "validate_order" => { "valid" => "charge_payment", "invalid" => nil }, "charge_payment" => { "paid" => nil } }
        )
        write_node("validate_order", %w[valid invalid])
        write_node("charge_payment", %w[paid])

        response = run_tests(flows: ["orders/purchase"])

        refute_predicate response, :error?
        assert_match(/2 runs, \d+ assertions, 0 failures, 0 errors/, response.content.first[:text])
      end

      def test_flow_test_does_not_run_node_tests_that_were_not_requested
        write_flow_definition("orders/purchase", { "validate_order" => { "valid" => nil } })
        write_node("validate_order", %w[valid])
        write_node_test("validate_order", failing_test("ValidateOrderTest"))

        response = run_tests(flows: ["orders/purchase"])

        refute_predicate response, :error?
        assert_match(/1 runs, \d+ assertions, 0 failures, 0 errors/, response.content.first[:text])
      end

      def test_fails_when_flow_uses_outcome_not_declared_by_node
        write_flow_definition("orders/purchase", { "validate_order" => { "valid" => nil, "invalid" => nil } })
        write_node("validate_order", %w[valid])

        response = run_tests(flows: ["orders/purchase"])

        assert_predicate response, :error?
        assert_match(/Outcome\(s\) used by the flow but not declared in .*OUTCOMES/, response.content.first[:text])
      end

      def test_fails_when_node_declares_outcome_without_edge_in_flow
        write_flow_definition("orders/purchase", { "validate_order" => { "valid" => nil } })
        write_node("validate_order", %w[valid invalid])

        response = run_tests(flows: ["orders/purchase"])

        assert_predicate response, :error?
        assert_match(/Outcome\(s\) declared in .*OUTCOMES but without an edge in the flow/, response.content.first[:text])
      end

      def test_fails_when_node_does_not_declare_outcomes
        write_flow_definition("orders/purchase", { "validate_order" => { "valid" => nil } })
        write_node_file("validate_order", "module ValidateOrder\n  class Node\n  end\nend\n")

        response = run_tests(flows: ["orders/purchase"])

        assert_predicate response, :error?
        assert_match(/must define OUTCOMES/, response.content.first[:text])
      end

      def test_fails_when_node_file_is_missing
        write_flow_definition("orders/purchase", { "validate_order" => { "valid" => nil } })

        response = run_tests(flows: ["orders/purchase"])

        assert_predicate response, :error?
        assert_match(%r{cannot load such file.*validate_order/node}, response.content.first[:text])
      end

      def test_runs_only_tests_of_the_given_nodes
        write_node_test("validate_order", passing_test("ValidateOrderTest"))
        write_node_test("unrelated_node", failing_test("UnrelatedNodeTest"))

        response = run_tests(nodes: ["validate_order"])

        refute_predicate response, :error?
        assert_match(/1 runs, \d+ assertions, 0 failures, 0 errors/, response.content.first[:text])
      end

      def test_runs_every_test_file_of_every_given_node
        write_node_test("validate_order", passing_test("ValidateOrderTest"))
        write_node_test("validate_order", passing_test("ValidateOrderRulesTest"), file_name: "rules_test.rb")
        write_node_test("charge_payment", passing_test("ChargePaymentTest"))

        response = run_tests(nodes: %w[validate_order charge_payment])

        refute_predicate response, :error?
        assert_match(/3 runs, \d+ assertions, 0 failures, 0 errors/, response.content.first[:text])
      end

      def test_runs_node_tests_and_flow_tests_together
        write_flow_definition("orders/purchase", { "validate_order" => { "valid" => nil } })
        write_node("validate_order", %w[valid])
        write_node_test("validate_order", passing_test("ValidateOrderTest"))

        response = run_tests(nodes: ["validate_order"], flows: ["orders/purchase"])

        refute_predicate response, :error?
        assert_match(/2 runs, \d+ assertions, 0 failures, 0 errors/, response.content.first[:text])
      end

      def test_reports_failing_node_tests
        write_node_test("validate_order", failing_test("ValidateOrderTest"))

        response = run_tests(nodes: ["validate_order"])

        assert_predicate response, :error?
        assert_match(/boom/, response.content.first[:text])
      end

      def test_returns_utf8_output_regardless_of_default_external_encoding
        write_node_test("validate_order", failing_test("ValidateOrderTest", "Należy wybrać miejsce"))

        response = with_default_external(Encoding::US_ASCII) do
          run_tests(nodes: ["validate_order"])
        end
        text = response.content.first[:text]

        assert_equal Encoding::UTF_8, text.encoding
        assert_includes text, "Należy wybrać miejsce"
      end

      private

      def run_tests(nodes: [], flows: [])
        RunTests.call(nodes: nodes, flows: flows, server_context: {})
      end

      def with_default_external(encoding)
        original = Encoding.default_external
        Encoding.default_external = encoding
        yield
      ensure
        Encoding.default_external = original
      end

      def write_node(node_name, outcomes)
        namespace = node_name.split("_").map(&:capitalize).join
        write_node_file(node_name, <<~RUBY)
          module #{namespace}
            class Node
              OUTCOMES = %i[#{outcomes.join(" ")}].freeze
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
