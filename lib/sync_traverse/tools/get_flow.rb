module SyncTraverse
  module Tools
    class GetFlow < FlowBase
      tool_name "get_flow"
      description "Returns the flow for the given flow_name as two text blocks: the flow graph as JSON and its phase. The approved flow is returned if it exists, else the draft, else the stable flow. Phase 'stable': no change in progress; the flow describes the working implementation. Phase 'draft': a change is being designed; update_flow changes it. Phase 'approved': the draft was approved with approve_drafts; the graph is locked until reopen_draft or promote_flows. Call this before modifying a flow."
      input_schema(
        properties: {
          flow_name: FLOW_NAME_SCHEMA
        },
        required: ["flow_name"]
      )

      def self.call(flow_name:, server_context:)
        with_valid_format(flow_names: [flow_name]) do
          text_response(JSON.pretty_generate(get_flow(flow_name)), "Phase: #{flow_phase(flow_name)}")
        end
      end
    end
  end
end
