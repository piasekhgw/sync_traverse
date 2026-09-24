module GraphFlow
  module Tools
    class GetFlow < Base
      description "Returns the complete flow for the given flow_name. Call this before modifying an existing flow."

      def self.tool_name
        "get_flow"
      end

      def execute(flow_name:)
        get_flow(flow_name).definition
      end
    end
  end
end
