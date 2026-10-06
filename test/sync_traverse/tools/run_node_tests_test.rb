require "test_helper"

module SyncTraverse
  module Tools
    class RunNodeTestsTest < SyncTraverse::TestCase
      def test_rejects_invalid_flow_name
        response = RunNodeTests.call(flow_name: "../escape", server_context: {})

        assert_predicate response, :error?
        assert_equal "Invalid name(s): ../escape", response.content.first[:text]
      end

      def test_errors_when_no_node_tests_found
        write_flow_definition("orders/purchase", { "validate_order" => { "valid" => nil } })

        response = RunNodeTests.call(flow_name: "orders/purchase", server_context: {})

        assert_predicate response, :error?
        assert_equal "No node tests found for flow: orders/purchase", response.content.first[:text]
      end

      def test_only_runs_tests_for_nodes_of_the_flow
        write_flow_definition(
          "orders/purchase",
          { "validate_order" => { "valid" => "charge_payment" }, "charge_payment" => { "paid" => nil } }
        )
        write_node_test("validate_order", passing_test("ValidateOrderTest"))
        write_node_test("unrelated_node", failing_test("UnrelatedNodeTest"))

        response = RunNodeTests.call(flow_name: "orders/purchase", server_context: {})

        refute_predicate response, :error?
        assert_match(/1 runs, 1 assertions, 0 failures, 0 errors/, response.content.first[:text])
      end

      def test_runs_every_test_file_in_node_directory
        write_flow_definition("orders/purchase", { "validate_order" => { "valid" => nil } })
        write_node_test("validate_order", passing_test("ValidateOrderTest"))
        write_node_test("validate_order", passing_test("ValidateOrderRulesTest"), file_name: "rules_test.rb")

        response = RunNodeTests.call(flow_name: "orders/purchase", server_context: {})

        refute_predicate response, :error?
        assert_match(/2 runs, 2 assertions, 0 failures, 0 errors/, response.content.first[:text])
      end

      def test_reports_failing_node_tests
        write_flow_definition("orders/purchase", { "validate_order" => { "valid" => nil } })
        write_node_test("validate_order", failing_test("ValidateOrderTest"))

        response = RunNodeTests.call(flow_name: "orders/purchase", server_context: {})

        assert_predicate response, :error?
        assert_match(/boom/, response.content.first[:text])
      end

      private

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

      def failing_test(class_name)
        <<~RUBY
          require "minitest/autorun"

          class #{class_name} < Minitest::Test
            def test_fails
              assert false, "boom"
            end
          end
        RUBY
      end
    end
  end
end
