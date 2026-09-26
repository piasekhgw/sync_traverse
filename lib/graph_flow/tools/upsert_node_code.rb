module GraphFlow
  module Tools
    class UpsertNodeCode < Base
      tool_name "upsert_node_code"
      description "Creates or replaces the code for the given node class."
      input_schema(
        properties: {
          node: { type: "string", description: "The node class name in CamelCase. It maps to a relative file path and may be namespaced (for example, Billing::ChargePayment)." },
          code: { type: "string", description: "The complete Ruby source code of the node class." }
        },
        required: ["node", "code"]
      )

      def self.call(node:, code:, server_context:)
        text_response(upsert_node_code(node, code))
      end
    end
  end
end
