module GraphFlow
  module Tools
    class GetFlow < Base
      description "Returns the complete flow for the given flow_name. Call this before modifying an existing flow."
      parameter :flow_name, description: "The flow name."

      def execute(flow_name:)
        get_flow(flow_name).definition
      end
    end
  end
end
