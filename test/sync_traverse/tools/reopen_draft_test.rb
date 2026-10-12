require "test_helper"

module SyncTraverse
  module Tools
    class ReopenDraftTest < SyncTraverse::TestCase
      def test_renames_approved_flow_back_to_draft
        write_flow_approved("orders/purchase", { "a" => { "ok" => nil } })

        response = ReopenDraft.call(flow_name: "orders/purchase", server_context: {})

        refute_predicate response, :error?
        assert_equal({ "a" => { "ok" => nil } }, JSON.parse(File.read(flow_draft_path("orders/purchase"))))
        refute_path_exists flow_approved_path("orders/purchase")
      end

      def test_renames_approved_diagram_back_to_draft_diagram
        write_flow_approved("orders/purchase", { "a" => { "ok" => nil } })
        File.write(flow_approved_diagram_path("orders/purchase"), "flowchart TD")

        ReopenDraft.call(flow_name: "orders/purchase", server_context: {})

        assert_equal "flowchart TD", File.read(flow_draft_diagram_path("orders/purchase"))
        refute_path_exists flow_approved_diagram_path("orders/purchase")
      end

      def test_allows_update_flow_afterwards
        write_flow_approved("orders/purchase", { "a" => { "ok" => nil } })
        ReopenDraft.call(flow_name: "orders/purchase", server_context: {})

        response = UpdateFlow.call(
          flow_name: "orders/purchase",
          add_transitions: [{ source: "a", target: nil, source_result: "other" }],
          server_context: {}
        )

        refute_predicate response, :error?
      end

      def test_warns_that_action_code_was_not_reverted
        write_flow_approved("orders/purchase", { "a" => { "ok" => nil } })

        response = ReopenDraft.call(flow_name: "orders/purchase", server_context: {})

        assert_equal "Success. Flow orders/purchase is a draft again.", response.content.first[:text]
        assert_match(/Action code and tests were not reverted/, response.content.last[:text])
      end

      def test_rejects_flow_not_approved
        write_flow_draft("orders/purchase", { "a" => { "ok" => nil } })

        response = ReopenDraft.call(flow_name: "orders/purchase", server_context: {})

        assert_predicate response, :error?
        assert_equal "Flow orders/purchase is not approved", response.content.first[:text]
      end
    end
  end
end
