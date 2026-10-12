require "test_helper"

module SyncTraverse
  module Tools
    class DiscardDraftTest < SyncTraverse::TestCase
      def test_removes_draft_files_and_keeps_stable_flow
        write_flow_stable("orders/purchase", { "a" => { "ok" => nil } })
        write_flow_draft("orders/purchase", { "a" => { "ok" => "b" }, "b" => {} })
        File.write(flow_draft_diagram_path("orders/purchase"), "flowchart TD")

        DiscardDraft.call(flow_name: "orders/purchase", server_context: {})

        refute_path_exists flow_draft_path("orders/purchase")
        refute_path_exists flow_draft_diagram_path("orders/purchase")
        assert_path_exists flow_stable_path("orders/purchase")
      end

      def test_removes_approved_files_and_keeps_stable_flow
        write_flow_stable("orders/purchase", { "a" => { "ok" => nil } })
        write_flow_approved("orders/purchase", { "a" => { "ok" => "b" }, "b" => {} })
        File.write(flow_approved_diagram_path("orders/purchase"), "flowchart TD")

        DiscardDraft.call(flow_name: "orders/purchase", server_context: {})

        refute_path_exists flow_approved_path("orders/purchase")
        refute_path_exists flow_approved_diagram_path("orders/purchase")
        assert_path_exists flow_stable_path("orders/purchase")
      end

      def test_removes_flow_directories_when_there_is_no_stable_flow
        write_flow_draft("orders/purchase", { "a" => { "ok" => nil } })

        DiscardDraft.call(flow_name: "orders/purchase", server_context: {})

        refute File.directory?(File.join(flows_dir, "orders"))
      end

      def test_keeps_namespace_directory_with_other_flows
        write_flow_draft("orders/purchase", { "a" => { "ok" => nil } })
        write_flow_stable("orders/refund", { "b" => { "ok" => nil } })

        DiscardDraft.call(flow_name: "orders/purchase", server_context: {})

        refute File.directory?(File.join(flows_dir, "orders", "purchase"))
        assert_path_exists flow_stable_path("orders/refund")
      end

      def test_warns_to_run_tests_when_stable_flow_exists
        write_flow_stable("orders/purchase", { "a" => { "ok" => nil } })
        write_flow_draft("orders/purchase", { "a" => { "ok" => "b" }, "b" => {} })

        response = DiscardDraft.call(flow_name: "orders/purchase", server_context: {})

        assert_equal "Success. Draft of flow orders/purchase was discarded.", response.content.first[:text]
        assert_match(/not reverted.*run_tests/, response.content.last[:text])
      end

      def test_reports_removal_without_warning_when_there_is_no_stable_flow
        write_flow_draft("orders/purchase", { "a" => { "ok" => nil } })

        response = DiscardDraft.call(flow_name: "orders/purchase", server_context: {})

        assert_equal(["Success. Draft of flow orders/purchase was discarded; the flow was removed."], response.content.map { |block| block[:text] })
      end

      def test_rejects_flow_without_draft
        write_flow_stable("orders/purchase", { "a" => { "ok" => nil } })

        response = DiscardDraft.call(flow_name: "orders/purchase", server_context: {})

        assert_predicate response, :error?
        assert_equal "No draft or approved version for flow orders/purchase", response.content.first[:text]
      end
    end
  end
end
