module SyncTraverse
  module Tools
    class GetAction < ActionBase
      tool_name "get_action"
      description "Returns the action as one JSON object with the fields 'files' and 'test_files'. 'files' maps the names of the files in the action directory (app/actions/<action>/) to their content: 'action.rb' is the action class itself; other files are action-local classes and other files such as templates. 'test_files' maps the names of the files in test/actions/<action>/ (the tests and their helper files, such as fixtures) to their content. Both are empty when the action does not exist. Call this before modifying an action."
      input_schema(
        properties: {
          action: ACTION_NAME_SCHEMA
        },
        required: ["action"]
      )

      def self.call(action:, server_context:)
        with_valid_format(action_names: [action]) do
          text_response(JSON.pretty_generate(read_action_files(action)))
        end
      end
    end
  end
end
