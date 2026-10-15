module SyncTraverse
  module Tools
    class UpdateActionCode < ActionCodeBase
      # RESULTS = %i[a b] (percent_list) or RESULTS = [:a, :b] (symbol_list)
      RESULTS_PATTERN = /RESULTS\s*=\s*(?:%i\[(?<percent_list>[^\]]*)\]|\[(?<symbol_list>[^\]]*)\])/

      tool_name "update_action_code"
      description "Creates, updates or deletes files owned by the given action. Files listed in 'files' are written (string) or deleted (null); files not listed are left untouched. The action file 'action.rb' must exist after the update, unless no files of the action remain: then the whole action is deleted (including its directory). Deleting an action is rejected while any flow uses it. Changing RESULTS of an action used by flows is rejected unless one of those flows is in the approved phase; any other change of the action is always allowed. RESULTS must be a literal array of Symbols. Actions are never deleted automatically."
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
            error_msg = error_message(action, files)
            return error_response(error_msg) if error_msg

            update_action_files(action, files)
            text_response("Success")
          end
        end

        private

        def error_message(action, files)
          flows = flows_using_action(action)
          remaining_files = remaining_action_files(action, files)

          if remaining_files.empty?
            "Cannot delete action #{action}, it is used by flow(s): #{flows.join(", ")}" if flows.any?
          elsif !remaining_files.include?(ActionCodeBase::ENTRY_FILE)
            "Action file #{ActionCodeBase::ENTRY_FILE} must exist"
          elsif flows.any? && flows.none? { |flow| approved?(flow) } && results_changed?(action, files)
            "Cannot change RESULTS of action #{action}: none of the flows using it (#{flows.join(", ")}) has an approved graph; " \
              "change the flows, get them approved by the developer and call approve_drafts first. " \
              "RESULTS must be a literal array of Symbols"
          end
        end

        def results_changed?(action, files)
          return false unless files.key?(ActionCodeBase::ENTRY_FILE)

          path = action_file_path(action, ActionCodeBase::ENTRY_FILE)
          old_results = declared_results(File.exist?(path) ? read_file(path) : nil)
          old_results.nil? || old_results != declared_results(files[ActionCodeBase::ENTRY_FILE])
        end

        # Reads RESULTS from the source text: the MCP server runs without the application loaded,
        # so the action file cannot be required here.
        # Returns nil unless RESULTS is a literal array of Symbols (%i[...] or [:a, :b]).
        def declared_results(code)
          match = code&.match(RESULTS_PATTERN)
          return unless match
          return match[:percent_list].split.sort if match[:percent_list]

          symbols = match[:symbol_list].split(",").map(&:strip)
          return unless symbols.all? { |symbol| symbol.match?(/\A:\w+\z/) }

          symbols.map { |symbol| symbol.delete_prefix(":") }.sort
        end
      end
    end
  end
end
