module SyncTraverse
  module Tools
    class GetFlow < FlowBase
      tool_name "get_flow"
      description "Returns the flow for the given flow_name as one JSON object with the fields 'definition' and 'test_files'. 'definition' maps every action of the flow to its results, and every result to the target action, or null when that result ends the flow; it is empty when the flow does not exist. 'test_files' maps the names of the files of the flow tests (stored in test/flows/<flow>/) to their content. Call this before changing a flow with update_flow."
      input_schema(
        properties: {
          flow_name: FLOW_NAME_SCHEMA
        },
        required: ["flow_name"]
      )

      def self.call(flow_name:, server_context:)
        with_valid_format(flow_names: [flow_name]) do
          test_files = flow_test_file_names(flow_name).to_h do |file_name|
            [file_name, read_file(flow_test_file_path(flow_name, file_name))]
          end

          text_response(JSON.pretty_generate(definition: read_flow(flow_name), test_files: test_files))
        end
      end
    end
  end
end
