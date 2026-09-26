module GraphFlow
  module Tools
    class RemoveNodeCode < Base
      tool_name "remove_node_code"
      description "Removes the code file for the given node class. Call this when deleting a node code."
      input_schema(
        properties: {
          node: { type: "string", description: "The node class name in CamelCase. It may be namespaced (for example, Billing::ChargePayment)." }
        },
        required: ["node"]
      )

      def self.call(node:, server_context:)
        text_response(remove_node_code(node))
      end
    end
  end
end
