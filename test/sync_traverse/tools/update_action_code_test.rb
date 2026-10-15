require "test_helper"

module SyncTraverse
  module Tools
    class UpdateActionCodeTest < SyncTraverse::TestCase
      def test_creates_action_file
        response = update("orders/validate_order", "action.rb" => "module Orders\nend\n")

        refute_predicate response, :error?
        assert_equal "Success", response.content.first[:text]
        assert_equal "module Orders\nend\n", File.read(action_path("orders/validate_order"))
      end

      def test_writes_multiple_files_in_one_call
        update(
          "orders/validate_order",
          "action.rb" => "'action'",
          "order.rb" => "'local'",
          "test.rb" => "'test'"
        )

        assert_equal "'action'", File.read(action_path("orders/validate_order"))
        assert_equal "'local'", File.read(action_path("orders/validate_order", "order.rb"))
        assert_equal "'test'", File.read(action_test_path("orders/validate_order"))
      end

      def test_stores_test_files_outside_action_directory
        update("orders/validate_order", "action.rb" => "'action'", "test.rb" => "'test'", "rules_test.rb" => "'rules'")

        assert_equal %w[action.rb], Dir.children(File.join(actions_dir, "orders/validate_order"))
        assert_equal %w[rules_test.rb test.rb], Dir.children(File.join(action_tests_dir, "orders/validate_order")).sort
      end

      def test_replaces_existing_file_and_keeps_unlisted_files
        write_action_code("orders/validate_order", "'old code'")
        write_action_test("orders/validate_order", "'test'")

        update("orders/validate_order", "action.rb" => "'new code'")

        assert_equal "'new code'", File.read(action_path("orders/validate_order"))
        assert_equal "'test'", File.read(action_test_path("orders/validate_order"))
      end

      def test_null_deletes_file
        write_action_code("orders/validate_order", "'code'")
        write_action_test("orders/validate_order", "'test'")

        update("orders/validate_order", "test.rb" => nil)

        refute_path_exists action_test_path("orders/validate_order")
        assert_path_exists action_path("orders/validate_order")
      end

      def test_rejects_update_that_leaves_action_without_action_file
        response = update("orders/validate_order", "order.rb" => "'local'")

        assert_predicate response, :error?
        assert_equal "Action file action.rb must exist", response.content.first[:text]
        refute_path_exists action_path("orders/validate_order", "order.rb")
      end

      def test_rejects_deleting_action_file_while_writing_other_files
        write_action_code("orders/validate_order", "'code'")

        response = update("orders/validate_order", "action.rb" => nil, "order.rb" => "'local'")

        assert_predicate response, :error?
        assert_path_exists action_path("orders/validate_order")
      end

      def test_writes_files_of_other_types
        update(
          "orders/validate_order",
          "action.rb" => "'action'",
          "schema.json" => "{}"
        )

        assert_equal "{}", File.read(action_path("orders/validate_order", "schema.json"))
      end

      def test_rejects_nested_files_in_action_directory
        response = update("orders/validate_order", "action.rb" => "'action'", "fixtures/order.yml" => "id: 1")

        assert_predicate response, :error?
        assert_equal "Invalid file name(s): fixtures/order.yml", response.content.first[:text]
        refute_path_exists action_path("orders/validate_order")
      end

      def test_deletes_whole_action_when_no_files_remain
        write_action_code("orders/validate_order", "'code'")
        write_action_test("orders/validate_order", "'test'")
        write_action_file("orders/validate_order", "{}", file_name: "schema.json")

        response = update(
          "orders/validate_order",
          "action.rb" => nil,
          "test.rb" => nil,
          "schema.json" => nil
        )

        assert_equal "Success", response.content.first[:text]
        assert_empty Dir.children(actions_dir)
        assert_empty Dir.children(action_tests_dir)
      end

      def test_deleting_only_some_files_never_deletes_the_action
        write_action_code("orders/validate_order", "'code'")
        write_action_test("orders/validate_order", "'test'")

        response = update("orders/validate_order", "test.rb" => nil)

        assert_equal "Success", response.content.first[:text]
        assert_path_exists action_path("orders/validate_order")
      end

      def test_rejects_deleting_action_used_by_a_flow
        write_flow_stable("orders/purchase", { "orders/validate_order" => { "valid" => nil } })
        write_flow_stable("orders/refund", { "orders/validate_order" => { "valid" => nil } })
        write_action_code("orders/validate_order", "'code'")

        response = update("orders/validate_order", "action.rb" => nil)

        assert_predicate response, :error?
        assert_equal "Cannot delete action orders/validate_order, it is used by flow(s): orders/purchase, orders/refund", response.content.first[:text]
        assert_path_exists action_path("orders/validate_order")
      end

      def test_rejects_deleting_action_used_only_by_a_flow_draft
        write_flow_draft("orders/purchase", { "orders/validate_order" => { "valid" => nil } })
        write_action_code("orders/validate_order", "'code'")

        response = update("orders/validate_order", "action.rb" => nil)

        assert_predicate response, :error?
        assert_equal "Cannot delete action orders/validate_order, it is used by flow(s): orders/purchase", response.content.first[:text]
      end

      def test_rejects_deleting_action_used_only_by_an_approved_flow
        write_flow_approved("orders/purchase", { "orders/validate_order" => { "valid" => nil } })
        write_action_code("orders/validate_order", "'code'")

        response = update("orders/validate_order", "action.rb" => nil)

        assert_predicate response, :error?
        assert_equal "Cannot delete action orders/validate_order, it is used by flow(s): orders/purchase", response.content.first[:text]
      end

      def test_rejects_results_change_of_action_used_only_by_stable_flow
        write_flow_stable("orders/purchase", { "orders/validate_order" => { "valid" => nil } })
        write_action_code("orders/validate_order", "RESULTS = %i[valid].freeze")

        response = update("orders/validate_order", "action.rb" => "RESULTS = %i[done].freeze")

        assert_predicate response, :error?
        assert_match(%r{\ACannot change RESULTS .* none of the flows using it \(orders/purchase\) has an approved graph}, response.content.first[:text])
        assert_equal "RESULTS = %i[valid].freeze", File.read(action_path("orders/validate_order"))
      end

      def test_rejects_unreadable_results_of_action_used_only_by_draft_flow
        write_flow_draft("orders/purchase", { "orders/validate_order" => { "valid" => nil } })
        write_action_code("orders/validate_order", "RESULTS = %i[valid].freeze")

        assert_predicate update("orders/validate_order", "action.rb" => "RESULTS = [VALID].freeze"), :error?
      end

      def test_allows_code_change_keeping_results_of_action_used_only_by_stable_flow
        write_flow_stable("orders/purchase", { "orders/validate_order" => { "valid" => nil, "invalid" => nil } })
        write_action_code("orders/validate_order", "RESULTS = %i[valid invalid].freeze")

        response = update("orders/validate_order", "action.rb" => "RESULTS = [:invalid, :valid].freeze\n# fixed", "order.rb" => "'local'")

        assert_equal "Success", response.content.first[:text]
        assert_equal "'local'", File.read(action_path("orders/validate_order", "order.rb"))
      end

      def test_allows_results_change_when_one_of_flows_using_action_is_approved
        write_flow_stable("orders/refund", { "orders/validate_order" => { "valid" => nil } })
        write_flow_approved("orders/purchase", { "orders/validate_order" => { "done" => nil } })
        write_action_code("orders/validate_order", "RESULTS = %i[valid].freeze")

        response = update("orders/validate_order", "action.rb" => "RESULTS = %i[done].freeze")

        assert_equal "Success", response.content.first[:text]
        assert_equal "RESULTS = %i[done].freeze", File.read(action_path("orders/validate_order"))
      end

      def test_allows_files_other_than_action_file_of_action_used_only_by_stable_flow
        write_flow_stable("orders/purchase", { "orders/validate_order" => { "valid" => nil } })
        write_action_code("orders/validate_order", "'code without results'")

        response = update("orders/validate_order", "order.rb" => "'local'", "test.rb" => "'test'")

        assert_equal "Success", response.content.first[:text]
      end

      def test_cannot_write_outside_action_directory
        response = update("orders/validate_order", "action.rb" => "'code'", "../other.rb" => "'x'")

        assert_predicate response, :error?
        assert_equal "Invalid file name(s): ../other.rb", response.content.first[:text]
        refute_path_exists action_path("orders/validate_order")
      end

      def test_rejects_invalid_file_names
        response = update("orders/validate_order", "../../escape.rb" => "'x'", "/abs.rb" => "'x'", "data" => "{}")

        assert_predicate response, :error?
        assert_equal "Invalid file name(s): ../../escape.rb, /abs.rb, data", response.content.first[:text]
      end

      def test_rejects_invalid_action_name
        response = update("../escape", "action.rb" => "'code'")

        assert_predicate response, :error?
        assert_equal "Invalid name(s): ../escape", response.content.first[:text]
      end

      private

      def update(action, files)
        UpdateActionCode.call(action: action, files: files, server_context: {})
      end
    end
  end
end
