require "test_helper"

module SyncTraverse
  module Tools
    class ApproveDraftTest < SyncTraverse::TestCase
      def test_renames_draft_to_approved_flow
        write_flow_draft("orders/purchase", { "a" => { "ok" => "b" }, "b" => {} })

        response = ApproveDraft.call(flow_name: "orders/purchase", server_context: {})

        refute_predicate response, :error?
        assert_path_exists flow_approved_path("orders/purchase")
        refute_path_exists flow_draft_path("orders/purchase")
      end

      def test_renames_draft_diagram_to_approved_diagram
        write_flow_draft("orders/purchase", { "a" => { "ok" => nil } })
        File.write(flow_draft_diagram_path("orders/purchase"), "flowchart TD")

        ApproveDraft.call(flow_name: "orders/purchase", server_context: {})

        assert_equal "flowchart TD", File.read(flow_approved_diagram_path("orders/purchase"))
        refute_path_exists flow_draft_diagram_path("orders/purchase")
      end

      def test_does_not_change_stable_flow
        write_flow_stable("orders/purchase", { "a" => { "ok" => nil } })
        write_flow_draft("orders/purchase", { "a" => { "ok" => "b" }, "b" => {} })

        ApproveDraft.call(flow_name: "orders/purchase", server_context: {})

        assert_equal({ "a" => { "ok" => nil } }, JSON.parse(File.read(flow_stable_path("orders/purchase"))))
      end

      def test_blocks_update_flow_afterwards
        write_flow_draft("orders/purchase", { "a" => { "ok" => nil } })
        ApproveDraft.call(flow_name: "orders/purchase", server_context: {})

        response = UpdateFlow.call(
          flow_name: "orders/purchase",
          add_edges: [{ source: "a", target: nil, source_outcome: "other" }],
          server_context: {}
        )

        assert_predicate response, :error?
        refute_path_exists flow_draft_path("orders/purchase")
      end

      def test_rejects_flow_without_draft
        write_flow_stable("orders/purchase", { "a" => { "ok" => nil } })

        response = ApproveDraft.call(flow_name: "orders/purchase", server_context: {})

        assert_predicate response, :error?
        assert_equal "No draft for flow orders/purchase; call update_flow first", response.content.first[:text]
      end

      def test_rejects_invalid_draft
        write_flow_draft("orders/purchase", { "a" => { "ok" => "b" }, "b" => { "back" => "a" } })

        response = ApproveDraft.call(flow_name: "orders/purchase", server_context: {})

        assert_predicate response, :error?
        refute_path_exists flow_approved_path("orders/purchase")
      end

      def test_rejects_flow_already_approved
        write_flow_approved("orders/purchase", { "a" => { "ok" => nil } })

        response = ApproveDraft.call(flow_name: "orders/purchase", server_context: {})

        assert_predicate response, :error?
        assert_equal "Flow orders/purchase is already approved", response.content.first[:text]
      end

      def test_rejects_invalid_flow_name
        response = ApproveDraft.call(flow_name: "../escape", server_context: {})

        assert_predicate response, :error?
        assert_equal "Invalid name(s): ../escape", response.content.first[:text]
      end
    end
  end
end
