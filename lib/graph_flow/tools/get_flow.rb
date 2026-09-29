module GraphFlow
  module Tools
    class GetFlow < FlowBase
      tool_name "get_flow"
      description "Returns the complete flow for the given flow_name. Call this before modifying an existing flow."
      input_schema(
        properties: {
          flow_name: { type: "string",
                       description: "The flow name. Must be a relative path; may be namespaced with a path, for example 'orders/purchase'." }
        },
        required: ["flow_name"]
      )

      def self.call(flow_name:, server_context:)
        with_input_validation(flow_name: flow_name) do
          text_response(JSON.pretty_generate(get_flow(flow_name).definition))
        end
      end
    end
  end
end
