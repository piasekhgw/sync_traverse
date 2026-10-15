module SyncTraverse
  module Tools
    class GetFlow < FlowBase
      tool_name "get_flow"
      description "Returns the flow for the given flow_name as one JSON object with the fields: phase, graph and flow_tests. 'graph' is the flow graph: the approved flow if it exists, else the draft, else the stable flow. 'flow_tests' maps the file names of the flow tests of the flow (stored in test/flows/<flow>/, changed with update_flow_tests) to their content. Phase 'none': the flow does not exist yet and the graph is empty; update_flow creates its draft. Phase 'stable': no change in progress; the flow describes the working implementation. Phase 'draft': a change is being designed; update_flow changes it. Phase 'approved': the draft was approved with approve_drafts; the graph is locked until reopen_draft or promote_flows. Call this before modifying a flow or its flow tests."
      input_schema(
        properties: {
          flow_name: FLOW_NAME_SCHEMA
        },
        required: ["flow_name"]
      )

      def self.call(flow_name:, server_context:)
        with_valid_format(flow_names: [flow_name]) do
          flow_tests = flow_test_files(flow_name).to_h { |file| [file, File.read(flow_test_path(flow_name, file))] }

          text_response(JSON.pretty_generate(phase: flow_phase(flow_name), graph: get_flow(flow_name), flow_tests: flow_tests))
        end
      end
    end
  end
end
