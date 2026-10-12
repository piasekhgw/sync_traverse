module SyncTraverse
  module Tools
    class UpdateActionCode < ActionCodeBase
      tool_name "update_action_code"
      description "Creates, updates or deletes files owned by the given action. Files listed in 'files' are written (string) or deleted (null); files not listed are left untouched. The action file 'action.rb' must exist after the update, unless no files of the action remain: then the whole action is deleted (including its directory). Deleting an action is rejected while any flow uses it. Actions are never deleted automatically."
      input_schema(
        properties: {
          action: {
            type: "string",
            description: "The action name in snake_case. Must be a relative path; may be namespaced with a path, for example 'orders/validate_order'."
          },
          files: {
            type: "object",
            additionalProperties: { type: %w[string null] },
            description: "JSON object: each key is a file name, each value is the complete new content of that file as a string, or null to delete the file. Example: {\"action.rb\": \"module Orders\\n  module ValidateOrder\\n    class Action\\n      ...\\n    end\\n  end\\nend\\n\", \"test.rb\": \"...\", \"old_helper.rb\": null}. Must be an object, never a plain string. File names must be lowercase snake_case with an extension (for example 'action.rb', 'order.rb', 'test.rb', 'schema.json') and live directly in the action directory (for action 'orders/validate_order' it is 'orders/validate_order/'); subdirectories are not allowed. Test files ('test.rb' or names ending with '_test.rb') are automatically stored in test/actions/<action>/ instead of app/actions/<action>/; just list them here like any other file. 'action.rb' is the action class itself. To delete an action, set all of its files to null."
          }
        },
        required: %w[action files]
      )

      class << self
        def call(action:, files:, server_context:)
          files = files.transform_keys(&:to_s)

          with_valid_format(action_names: [action], file_names: files.keys) do
            remaining_files = remaining_action_files(action, files)
            if remaining_files.empty?
              flows = flows_using_action(action)
              return error_response("Cannot delete action #{action}, it is used by flow(s): #{flows.join(", ")}") if flows.any?
            elsif !remaining_files.include?(ActionCodeBase::ENTRY_FILE)
              return error_response("Action file #{ActionCodeBase::ENTRY_FILE} must exist")
            end

            update_action_files(action, files)
            text_response("Success")
          end
        end
      end
    end
  end
end
