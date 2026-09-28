module GraphFlow
  module Tools
    class GetNodeCode < NodeCodeBase
      tool_name "get_node_code"
      description "Returns the code for the given node. Call this before modifying a node code."
      input_schema(
        properties: {
          node: { type: "string", description: "The node name in snake_case. Must be a relative path; may be namespaced with a path, for example 'orders/validate_order'." }
        },
        required: ["node"]
      )

      def self.call(node:, server_context:)
        text_response(get_node_code(node))
      end
    end
  end
end
