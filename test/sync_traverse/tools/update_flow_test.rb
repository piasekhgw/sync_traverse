require "test_helper"

module SyncTraverse
  module Tools
    class UpdateFlowTest < SyncTraverse::TestCase
      PURCHASE = {
        "orders/validate_order" => { "valid" => "orders/charge_payment", "invalid" => nil },
        "orders/charge_payment" => { "paid" => nil }
      }.freeze

      def test_saves_definition_with_start_action_first_and_generated_diagram
        response = update(definition: PURCHASE.to_a.reverse.to_h)

        assert_equal "Success", response.content.first[:text]
        assert_equal PURCHASE.keys, JSON.parse(File.read(flow_definition_path("orders/purchase"))).keys
        assert_equal Flow.new(PURCHASE).to_mermaid, File.read(flow_diagram_path("orders/purchase"))
      end

      def test_replaces_whole_definition
        write_flow("orders/purchase", PURCHASE)

        update(definition: { "orders/charge_payment" => { "paid" => nil, "declined" => nil } })

        assert_equal(
          { "orders/charge_payment" => { "paid" => nil, "declined" => nil } },
          JSON.parse(File.read(flow_definition_path("orders/purchase")))
        )
      end

      def test_accepts_symbol_keys
        response = update(definition: { "orders/validate_order": { valid: nil } })

        refute_predicate response, :error?
        assert_equal({ "orders/validate_order" => { "valid" => nil } }, JSON.parse(File.read(flow_definition_path("orders/purchase"))))
      end

      def test_writes_definition_and_tests_in_one_call
        update(definition: PURCHASE, test_files: { "test.rb" => "'test'", "paths_test.rb" => "'paths'" })

        assert_path_exists flow_definition_path("orders/purchase")
        assert_equal "'test'", File.read(flow_test_path("orders/purchase"))
        assert_equal "'paths'", File.read(flow_test_path("orders/purchase", "paths_test.rb"))
      end

      def test_writes_only_tests_of_existing_flow_and_keeps_unlisted_files
        write_flow("orders/purchase", PURCHASE)
        write_flow_test("orders/purchase", "'old'")
        write_flow_test("orders/purchase", "'paths'", file_name: "paths_test.rb")

        update(test_files: { "test.rb" => "'new'" })

        assert_equal "'new'", File.read(flow_test_path("orders/purchase"))
        assert_equal "'paths'", File.read(flow_test_path("orders/purchase", "paths_test.rb"))
        refute_path_exists flow_diagram_path("orders/purchase")
      end

      def test_null_deletes_test_file_and_empty_directories
        write_flow("orders/purchase", PURCHASE)
        write_flow_test("orders/purchase", "'test'")

        update(test_files: { "test.rb" => nil })

        assert_empty Dir.children(flow_tests_dir)
      end

      def test_rejects_tests_of_flow_that_does_not_exist
        response = update(test_files: { "test.rb" => "'test'" })

        assert_predicate response, :error?
        assert_equal "Flow not found: orders/purchase; pass its definition", response.content.first[:text]
        refute_path_exists flow_test_path("orders/purchase")
      end

      def test_writes_and_deletes_helper_files
        update(definition: PURCHASE, test_files: { "test.rb" => "'test'", "fixture.json" => "{}" })
        update(test_files: { "test.rb" => nil })

        refute_path_exists flow_test_path("orders/purchase")
        assert_equal "{}", File.read(flow_test_path("orders/purchase", "fixture.json"))
      end

      def test_rejects_invalid_file_names
        response = update(definition: PURCHASE, test_files: { "../test.rb" => "'test'" })

        assert_predicate response, :error?
        refute_path_exists flow_definition_path("orders/purchase")
      end

      def test_rejects_invalid_graph_without_saving_anything
        write_flow("orders/purchase", PURCHASE)

        response = update(
          definition: { "a" => { "ok" => "b" }, "b" => { "back" => "a" }, "c" => {}, "d" => { "ok" => "missing" } },
          test_files: { "test.rb" => "'test'" }
        )

        assert_equal(
          [
            "Target action(s) not defined in the flow: missing",
            "Action(s) without results: c",
            "Flow must be acyclic",
            "Flow must have exactly one source action, found: c, d"
          ].join("\n"),
          response.content.first[:text]
        )
        assert_equal PURCHASE, JSON.parse(File.read(flow_definition_path("orders/purchase")))
        refute_path_exists flow_test_path("orders/purchase")
      end

      def test_allows_several_results_leading_to_same_target_or_end
        response = update(definition: { "a" => { "x" => "b", "y" => "b" }, "b" => { "created" => nil, "invalid" => nil } })

        refute_predicate response, :error?
      end

      def test_empty_definition_deletes_flow_diagram_and_tests
        update(definition: PURCHASE, test_files: { "test.rb" => "'test'" })

        response = update(definition: {})

        assert_equal "Success. The definition is empty; flow orders/purchase and its test files were deleted.", response.content.first[:text]
        assert_empty Dir.children(flows_dir)
        assert_empty Dir.children(flow_tests_dir)
      end

      def test_rejects_tests_together_with_empty_definition
        write_flow("orders/purchase", PURCHASE)

        response = update(definition: {}, test_files: { "test.rb" => "'test'" })

        assert_predicate response, :error?
        assert_equal "Cannot write test files while deleting flow orders/purchase with an empty definition", response.content.first[:text]
        assert_path_exists flow_definition_path("orders/purchase")
      end

      def test_rejects_invalid_names
        response = UpdateFlow.call(flow_name: "orders/purchase", definition: { "../escape" => { "ok" => nil } }, server_context: {})

        assert_predicate response, :error?
        assert_equal "Invalid name(s): ../escape", response.content.first[:text]
      end

      private

      def update(**arguments)
        UpdateFlow.call(flow_name: "orders/purchase", server_context: {}, **arguments)
      end
    end
  end
end
