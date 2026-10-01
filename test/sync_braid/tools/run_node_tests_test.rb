require "test_helper"

module SyncBraid
  module Tools
    class RunNodeTestsTest < SyncBraid::TestCase
      def test_rejects_invalid_flow_name
        response = RunNodeTests.call(flow_name: "../escape", testing_framework: "minitest", server_context: {})

        assert_predicate response, :error?
        assert_equal "Invalid name(s): ../escape", response.content.first[:text]
      end

      def test_errors_when_no_node_tests_found
        write_flow_definition("orders/purchase", { "validate_order" => { "valid" => nil } })

        response = RunNodeTests.call(flow_name: "orders/purchase", testing_framework: "minitest", server_context: {})

        assert_predicate response, :error?
        assert_equal "No node tests found for flow: orders/purchase", response.content.first[:text]
      end

      def test_only_runs_tests_for_nodes_that_have_them
        write_flow_definition(
          "orders/purchase",
          { "validate_order" => { "valid" => "charge_payment" }, "charge_payment" => { "paid" => nil } }
        )
        write_node_test("validate_order", <<~RUBY)
          require "minitest/autorun"

          class ValidateOrderTest < Minitest::Test
            def test_passes
              assert true
            end
          end
        RUBY

        response = RunNodeTests.call(flow_name: "orders/purchase", testing_framework: "minitest", server_context: {})

        refute_predicate response, :error?
        assert_match(/1 runs, 1 assertions, 0 failures, 0 errors/, response.content.first[:text])
      end

      def test_runs_passing_minitest_node_tests
        write_flow_definition("orders/purchase", { "validate_order" => { "valid" => nil } })
        write_node_test("validate_order", <<~RUBY)
          require "minitest/autorun"

          class ValidateOrderTest < Minitest::Test
            def test_passes
              assert true
            end
          end
        RUBY

        response = RunNodeTests.call(flow_name: "orders/purchase", testing_framework: "minitest", server_context: {})

        refute_predicate response, :error?
        assert_match(/1 runs, 1 assertions, 0 failures, 0 errors/, response.content.first[:text])
      end

      def test_reports_failing_minitest_node_tests
        write_flow_definition("orders/purchase", { "validate_order" => { "valid" => nil } })
        write_node_test("validate_order", <<~RUBY)
          require "minitest/autorun"

          class ValidateOrderTest < Minitest::Test
            def test_fails
              assert false, "boom"
            end
          end
        RUBY

        response = RunNodeTests.call(flow_name: "orders/purchase", testing_framework: "minitest", server_context: {})

        assert_predicate response, :error?
        assert_match(/boom/, response.content.first[:text])
      end

      def test_runs_passing_rspec_node_tests
        write_flow_definition("orders/purchase", { "validate_order" => { "valid" => nil } })
        write_node_test("validate_order", <<~RUBY, suffix: "spec.rb")
          RSpec.describe "validate_order" do
            it "passes" do
              expect(true).to be(true)
            end
          end
        RUBY

        response = RunNodeTests.call(flow_name: "orders/purchase", testing_framework: "rspec", server_context: {})

        refute_predicate response, :error?
        assert_match(/1 example, 0 failures/, response.content.first[:text])
      end

      def test_reports_failing_rspec_node_tests
        write_flow_definition("orders/purchase", { "validate_order" => { "valid" => nil } })
        write_node_test("validate_order", <<~RUBY, suffix: "spec.rb")
          RSpec.describe "validate_order" do
            it "fails" do
              expect(false).to be(true)
            end
          end
        RUBY

        response = RunNodeTests.call(flow_name: "orders/purchase", testing_framework: "rspec", server_context: {})

        assert_predicate response, :error?
        assert_match(/1 example, 1 failure/, response.content.first[:text])
      end
    end
  end
end
