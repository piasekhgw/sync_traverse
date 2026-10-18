module SyncTraverse
  module Tools
    class UpdateFlow < FlowBase
      tool_name "update_flow"
      description "Replaces the definition of the flow and/or creates, updates or deletes its test files. The definition is saved to app/flows/<flow>/definition.json together with a Mermaid diagram generated from it (definition.mmd); SyncTraverse::Runner executes the saved definition right away. The definition is validated as a single graph: every target must be an action of the flow, every action needs at least one result, and the flow must be acyclic with exactly one source action, from which every action is reachable. It is not checked against the action code: run_tests checks that the results of every action match its RESULTS. Nothing is saved when validation fails. An empty definition deletes the flow, its diagram and all its test files in test/flows/<flow>/. It never creates or deletes action code."
      input_schema(
        properties: {
          flow_name: FLOW_NAME_SCHEMA,
          definition: {
            type: "object",
            additionalProperties: {
              type: "object",
              additionalProperties: { type: %w[string null] }
            },
            description: "The complete new definition of the flow, replacing the current one. Each key is an action name, each value maps every result of the action to the target action name, or to null when that result ends the flow. Example: {\"orders/validate_order\": {\"valid\": \"orders/charge_payment\", \"invalid\": null}, \"orders/charge_payment\": {\"paid\": null, \"declined\": null}}. An empty object deletes the flow. Omit it to change only the test files."
          },
          test_files: {
            type: "object",
            additionalProperties: { type: %w[string null] },
            description: "Test files of the flow: each key is a file name, each value is the complete new content of that file as a string, or null to delete the file. Files not listed are left untouched. Test files are named 'test.rb' or end with '_test.rb' (run_tests runs only them); other files, such as fixtures, are stored but not run. File names must be lowercase snake_case with an extension and live directly in test/flows/<flow>/; subdirectories are not allowed. Must be an object, never a plain string."
          }
        },
        required: ["flow_name"]
      )

      class << self
        def call(flow_name:, server_context:, definition: nil, test_files: {})
          definition = normalize(definition)
          test_files = test_files.transform_keys(&:to_s)

          with_valid_format(flow_names: [flow_name], action_names: action_names(definition), file_names: test_files.keys) do
            errors = validation_errors(flow_name, definition, test_files)
            return error_response(errors.join("\n")) if errors.any?

            if definition && definition.empty?
              delete_flow(flow_name)
              return text_response("Success. The definition is empty; flow #{flow_name} and its test files were deleted.")
            end

            save_flow(flow_name, Flow.new(definition)) if definition
            update_test_files(flow_name, test_files)
            text_response("Success")
          end
        end

        private

        # Arguments arrive with Symbol keys; action and result names are Strings everywhere else.
        def normalize(definition)
          definition&.to_h { |action, results| [action.to_s, results.to_h { |result, target| [result.to_s, target] }] }
        end

        def action_names(definition)
          definition.to_h.flat_map { |action, results| [action, *results.values] }
        end

        def validation_errors(flow_name, definition, test_files)
          return ["Flow not found: #{flow_name}; pass its definition"] if definition.nil? && !flow_exists?(flow_name)
          return ["Cannot write test files while deleting flow #{flow_name} with an empty definition"] if definition&.empty? && test_files.any?

          definition ? GraphValidator.new(definition).call : []
        end

        def update_test_files(flow_name, test_files)
          test_files.each do |file_name, content|
            path = flow_test_file_path(flow_name, file_name)
            content.nil? ? delete_file(path, flow_tests_dir) : write_file(path, content)
          end
        end
      end
    end
  end
end
