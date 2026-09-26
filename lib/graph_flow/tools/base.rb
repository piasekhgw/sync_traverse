require "fileutils"
require "active_support/core_ext/string/inflections"

module GraphFlow
  module Tools
    class Base < MCP::Tool
      EDGE_SCHEMA = {
        type: "object",
        properties: {
          source: { type: "string", description: "Source node name." },
          target: { type: "string", description: "Target node name." },
          source_outcome: { type: "string", description: "Outcome returned by the source node that selects this edge." }
        },
        required: ["source", "target", "source_outcome"]
      }.freeze

      class << self
        private

        def get_flow(flow_name)
          flow_file_path = flow_path(flow_name)
          flow_definition = File.exist?(flow_file_path) ? JSON.parse(File.read(flow_file_path)) : {}

          GraphFlow::Flow.new(flow_definition)
        end

        def save_flow(flow_name, flow)
          File.write(flow_path(flow_name), JSON.pretty_generate(flow.definition))
        end

        def remove_flow(flow_name)
          flow_file_path = flow_path(flow_name)
          return false unless File.exist?(flow_file_path)

          File.delete(flow_file_path)
          true
        end

        def get_node_code(node_class_name)
          node_file_path = File.join(nodes_dir, "#{node_class_name.underscore}.rb")
          File.exist?(node_file_path) ? File.read(node_file_path) : nil
        end

        def upsert_node_code(node_class_name, code)
          node_file_path = File.join(nodes_dir, "#{node_class_name.underscore}.rb")
          FileUtils.mkdir_p(File.dirname(node_file_path))
          File.write(node_file_path, code)
          true
        end

        def remove_node_code(node_class_name)
          node_file_path = File.join(nodes_dir, "#{node_class_name.underscore}.rb")
          return false unless File.exist?(node_file_path)

          File.delete(node_file_path)
          true
        end

        def flow_path(flow_name)
          File.join(flows_dir, "#{flow_name}.json")
        end

        def flows_dir
          'lib/flows' # TODO: Replace with a configuration variable
        end

        def nodes_dir
          'lib/nodes' # TODO: Replace with a configuration variable
        end

        def text_response(payload)
          MCP::Tool::Response.new([{ type: "text", text: JSON.pretty_generate(payload) }])
        end
      end
    end
  end
end
