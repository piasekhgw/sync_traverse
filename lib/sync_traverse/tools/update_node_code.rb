module SyncTraverse
  module Tools
    class UpdateNodeCode < NodeCodeBase
      tool_name "update_node_code"
      description "Creates, updates or deletes files owned by the given node. Files listed in 'files' are written (string) or deleted (null); files not listed are left untouched. The node file 'node.rb' must exist after the update, unless no files of the node remain: then the whole node is deleted (including its directory). Deleting a node is rejected while any flow uses it. Nodes are never deleted automatically."
      input_schema(
        properties: {
          node: {
            type: "string",
            description: "The node name in snake_case. Must be a relative path; may be namespaced with a path, for example 'orders/validate_order'."
          },
          files: {
            type: "object",
            additionalProperties: { type: %w[string null] },
            description: "JSON object: each key is a file name, each value is the complete new content of that file as a string, or null to delete the file. Example: {\"node.rb\": \"module Orders\\n  module ValidateOrder\\n    class Node\\n      ...\\n    end\\n  end\\nend\\n\", \"test.rb\": \"...\", \"old_helper.rb\": null}. Must be an object, never a plain string. File names must be lowercase snake_case with an extension (for example 'node.rb', 'order.rb', 'test.rb', 'schema.json') and live directly in the node directory (for node 'orders/validate_order' it is 'orders/validate_order/'); subdirectories are not allowed. 'node.rb' is the node class itself. To delete a node, set all of its files to null."
          }
        },
        required: %w[node files]
      )

      class << self
        def call(node:, files:, server_context:)
          files = files.transform_keys(&:to_s)

          with_input_validation(node_names: [node], file_names: files.keys) do
            remaining_files = remaining_node_files(node, files)
            if remaining_files.empty?
              flows = flows_using_node(node)
              return error_response("Cannot delete node #{node}, it is used by flow(s): #{flows.join(", ")}") if flows.any?
            elsif !remaining_files.include?(NodeCodeBase::ENTRY_FILE)
              return error_response("Node file #{NodeCodeBase::ENTRY_FILE} must exist")
            end

            update_node_files(node, files)
            text_response("Success")
          end
        end
      end
    end
  end
end
