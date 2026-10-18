module SyncTraverse
  module Tools
    class UpdateAction < ActionBase
      tool_name "update_action"
      description "Creates, updates or deletes the files of the given action ('files', stored in app/actions/<action>/) and of its tests ('test_files', stored in test/actions/<action>/). Listed files are written (string) or deleted (null); files not listed are left untouched. To delete an action, delete all of its files and test files: its directories are then removed. Changes are not checked against the flows using the action, neither changes of RESULTS nor deleting the action: run_tests reports flows whose transitions no longer match the RESULTS of their actions or that use a missing action."
      input_schema(
        properties: {
          action: ACTION_NAME_SCHEMA,
          files: {
            type: "object",
            additionalProperties: { type: %w[string null] },
            description: "Files of the action: each key is a file name, each value is the complete new content of that file as a string, or null to delete it. Example: {\"action.rb\": \"module Orders\\n  module ValidateOrder\\n    class Action\\n      ...\\n    end\\n  end\\nend\\n\", \"old_helper.rb\": null}. Must be an object, never a plain string. File names must be lowercase snake_case with an extension (for example 'action.rb', 'order.rb', 'schema.json') and live directly in app/actions/<action>/; subdirectories are not allowed. Test files ('test.rb' or names ending with '_test.rb') belong to 'test_files'."
          },
          test_files: {
            type: "object",
            additionalProperties: { type: %w[string null] },
            description: "Test files of the action, in the same format as 'files', stored directly in test/actions/<action>/. Test files are named 'test.rb' or end with '_test.rb' (run_tests runs only them); other files, such as fixtures, are stored but not run."
          }
        },
        required: ["action"]
      )

      def self.call(action:, server_context:, files: {}, test_files: {})
        files = files.transform_keys(&:to_s)
        test_files = test_files.transform_keys(&:to_s)

        with_valid_format(action_names: [action], file_names: files.keys + test_files.keys) do
          misplaced = files.keys.select { |file_name| test_file?(file_name) }
          return error_response("Pass test files in test_files: #{misplaced.join(", ")}") if misplaced.any?

          write_action_files(action, files, test_files)
          text_response("Success")
        end
      end
    end
  end
end
