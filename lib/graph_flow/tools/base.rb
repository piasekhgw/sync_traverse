module GraphFlow
  module Tools
    class Base < RubyLLM::Tool
      private

      def get_flow(flow_name)
        flow_file_path = flow_path(flow_name)
        flow_definition = File.exist?(flow_file_path) ? JSON.parse(File.read(flow_file_path)) : {}

        GraphFlow::Flow.new(flow_definition)
      end

      def save_flow(flow_name, flow)
        File.write(flow_path(flow_name), JSON.pretty_generate(flow.definition))
      end

      def flow_path(flow_name)
        File.join(flows_dir, "#{flow_name}.json")
      end

      def flows_dir
        'lib/flows' # TODO: Replace with a configuration variable
      end
    end
  end
end
