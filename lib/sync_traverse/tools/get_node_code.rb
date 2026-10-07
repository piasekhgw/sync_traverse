module SyncTraverse
  module Tools
    class GetNodeCode < NodeCodeBase
      tool_name "get_node_code"
      description "Returns all files owned by the given node as a JSON object mapping file names to their content. The code files live directly in the node directory (app/nodes/<node>/): 'node.rb' is the node class itself; other files are node-local classes and other files. Test files ('test.rb' or '*_test.rb') live in test/nodes/<node>/. Returns an empty object if the node does not exist. Call this before modifying a node."
      input_schema(
        properties: {
          node: {
            type: "string",
            description: "The node name in snake_case. Must be a relative path; may be namespaced with a path, for example 'orders/validate_order'."
          }
        },
        required: ["node"]
      )

      def self.call(node:, server_context:)
        with_input_validation(node_names: [node]) do
          text_response(JSON.pretty_generate(get_node_code(node)))
        end
      end
    end
  end
end
