module SyncTraverse
  module Tools
    class GetActionCode < ActionCodeBase
      tool_name "get_action_code"
      description "Returns all files owned by the given action as a JSON object mapping file names to their content. The code files live directly in the action directory (app/actions/<action>/): 'action.rb' is the action class itself; other files are action-local classes and other files. Test files ('test.rb' or '*_test.rb') live in test/actions/<action>/. Returns an empty object if the action does not exist. Call this before modifying an action."
      input_schema(
        properties: {
          action: {
            type: "string",
            description: "The action name in snake_case. Must be a relative path; may be namespaced with a path, for example 'orders/validate_order'."
          }
        },
        required: ["action"]
      )

      def self.call(action:, server_context:)
        with_valid_format(action_names: [action]) do
          text_response(JSON.pretty_generate(get_action_code(action)))
        end
      end
    end
  end
end
