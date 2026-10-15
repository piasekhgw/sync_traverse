require "test_helper"

module SyncTraverse
  module Tools
    class UpdateFlowTestsTest < SyncTraverse::TestCase
      def setup
        super
        write_flow_stable("orders/purchase", { "validate_order" => { "valid" => nil } })
      end

      def test_writes_test_files_of_the_flow
        response = update("orders/purchase", "test.rb" => "'test'", "paths_test.rb" => "'paths'")

        assert_equal "Success", response.content.first[:text]
        assert_equal "'test'", File.read(flow_test_path("orders/purchase"))
        assert_equal "'paths'", File.read(flow_test_path("orders/purchase", "paths_test.rb"))
      end

      def test_replaces_file_and_keeps_unlisted_files
        write_flow_test("orders/purchase", "'old'")
        write_flow_test("orders/purchase", "'paths'", file_name: "paths_test.rb")

        update("orders/purchase", "test.rb" => "'new'")

        assert_equal "'new'", File.read(flow_test_path("orders/purchase"))
        assert_equal "'paths'", File.read(flow_test_path("orders/purchase", "paths_test.rb"))
      end

      def test_null_deletes_file_and_empty_directories
        write_flow_test("orders/purchase", "'test'")

        update("orders/purchase", "test.rb" => nil)

        assert_empty Dir.children(flow_tests_dir)
      end

      def test_writes_tests_in_draft_and_approved_phases
        write_flow_draft("billing/invoice", { "charge" => { "paid" => nil } })
        write_flow_approved("orders/refund", { "refund" => { "refunded" => nil } })

        update("billing/invoice", "test.rb" => "'draft'")
        update("orders/refund", "test.rb" => "'approved'")

        assert_path_exists flow_test_path("billing/invoice")
        assert_path_exists flow_test_path("orders/refund")
      end

      def test_rejects_flow_that_does_not_exist
        response = update("orders/missing", "test.rb" => "'test'")

        assert_predicate response, :error?
        assert_equal "Flow not found: orders/missing", response.content.first[:text]
        refute_path_exists flow_test_path("orders/missing")
      end

      def test_rejects_files_that_are_not_test_files
        response = update("orders/purchase", "test.rb" => "'test'", "helper.rb" => "'helper'")

        assert_predicate response, :error?
        assert_match(/\AInvalid test file name\(s\): helper\.rb;/, response.content.first[:text])
        refute_path_exists flow_test_path("orders/purchase")
      end

      def test_rejects_invalid_names
        response = update("../escape", "../test.rb" => "'test'")

        assert_predicate response, :error?
        assert_equal "Invalid name(s): ../escape", response.content.first[:text]
      end

      private

      def update(flow_name, files)
        UpdateFlowTests.call(flow_name: flow_name, files: files, server_context: {})
      end
    end
  end
end
