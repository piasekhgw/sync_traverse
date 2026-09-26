module GraphFlow
  module Tools
    class RemoveFlow < Base
      tool_name "remove_flow"
      description "Removes the flow file for the given flow_name. Call this when deleting a flow."
      input_schema(
        properties: {
          flow_name: { type: "string", description: "The flow name." }
        },
        required: ["flow_name"]
      )

      def self.call(flow_name:, server_context:)
        text_response(remove_flow(flow_name))
      end
    end
  end
end
