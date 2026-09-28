module GraphFlow
  module Tools
    class UpdateNodeCode < NodeCodeBase
      tool_name "update_node_code"
      description "Creates or replaces the code for the given node."
      input_schema(
        properties: {
          node: { type: "string", description: "The node name in snake_case. Must be a relative path; may be namespaced with a path, for example 'orders/validate_order'." },
          code: { type: "string", description: "The complete Ruby source code of the node." }
        },
        required: ["node", "code"]
      )

      def self.call(node:, code:, server_context:)
        text_response(update_node_code(node, code))
      end
    end
  end
end
