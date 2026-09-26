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
          if flow.definition.empty?
            remove_flow(flow_name)
            return
          end

          flow_file_path = flow_path(flow_name)
          FileUtils.mkdir_p(File.dirname(flow_file_path))
          File.write(flow_file_path, JSON.pretty_generate(flow.definition))
        end

        def remove_flow(flow_name)
          flow_file_path = flow_path(flow_name)
          return false unless File.exist?(flow_file_path)

          File.delete(flow_file_path)
          remove_empty_parent_dirs(File.dirname(flow_file_path), flows_dir)
          true
        end

        def get_node_code(node_class_name)
          node_file_path = node_path(node_class_name)
          File.exist?(node_file_path) ? File.read(node_file_path) : nil
        end

        def upsert_node_code(node_class_name, code)
          node_file_path = node_path(node_class_name)
          FileUtils.mkdir_p(File.dirname(node_file_path))
          File.write(node_file_path, code)
          true
        end

        def remove_node_code(node_class_name)
          node_file_path = node_path(node_class_name)
          return false unless File.exist?(node_file_path)

          File.delete(node_file_path)
          remove_empty_parent_dirs(File.dirname(node_file_path), nodes_dir)
          true
        end

        # TODO: Validate that node_class_name does not escape nodes_dir (e.g. via "../").
        def node_path(node_class_name)
          File.join(nodes_dir, "#{node_class_name.underscore}.rb")
        end

        # TODO: Validate that flow_name does not escape flows_dir (e.g. via "../").
        def flow_path(flow_name)
          File.join(flows_dir, "#{flow_name}.json")
        end

        def remove_empty_parent_dirs(dir, stop_dir)
          while dir != stop_dir && Dir.empty?(dir)
            Dir.rmdir(dir)
            dir = File.dirname(dir)
          end
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
