module GraphFlow
  module Tools
    class GetNodeCode < Base
      tool_name "get_node_code"
      description "Returns the code for the given node class. Call this before modifying a node code."
      input_schema(
        properties: {
          node: { type: "string", description: "The node class name in CamelCase. It maps to a relative file path and may be namespaced (for example, Billing::ChargePayment)." }
        },
        required: ["node"]
      )

      def self.call(node:, server_context:)
        text_response(get_node_code(node))
      end
    end
  end
end
