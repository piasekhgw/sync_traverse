module SyncTraverse
  module Tools
    class UpdateFlowTests < FlowBase
      tool_name "update_flow_tests"
      description "Creates, updates or deletes the flow tests of the given flow. A flow test runs the flow with SyncTraverse::Runner through the real actions and checks the returned result and the shared context, so it detects actions that no longer agree on the data they pass to each other through the context. Files listed in 'files' are written (string) or deleted (null); files not listed are left untouched. The files are stored in test/flows/<flow>/; get_flow returns them. run_tests and promote_flows run them for the flow. The flow must exist (any phase). Flow tests are deleted only together with the flow."
      input_schema(
        properties: {
          flow_name: FLOW_NAME_SCHEMA,
          files: {
            type: "object",
            additionalProperties: { type: %w[string null] },
            description: "JSON object: each key is a test file name, 'test.rb' or a name ending with '_test.rb', each value is the complete new content of that file as a string, or null to delete the file. Subdirectories are not allowed. Must be an object, never a plain string."
          }
        },
        required: %w[flow_name files]
      )

      def self.call(flow_name:, files:, server_context:)
        files = files.transform_keys(&:to_s)

        with_valid_format(flow_names: [flow_name], file_names: files.keys) do
          return error_response("Flow not found: #{flow_name}") if flow_phase(flow_name) == "none"

          invalid_files = files.keys.reject { |file| test_file?(file) }
          return error_response("Invalid test file name(s): #{invalid_files.join(", ")}; use test.rb or a name ending with _test.rb") if invalid_files.any?

          files.each do |file, code|
            path = flow_test_path(flow_name, file)
            code.nil? ? delete_file(path, flow_tests_dir) : write_file(path, code)
          end
          text_response("Success")
        end
      end
    end
  end
end
