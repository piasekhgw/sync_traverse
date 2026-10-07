require "fileutils"

module SyncTraverse
  module Tools
    class Base < MCP::Tool
      NAME_PATTERN = %r{\A[a-z0-9_]+(/[a-z0-9_]+)*\z}
      FILE_PATTERN = /\A[a-z0-9_]+(\.[a-z0-9]+)+\z/

      class << self
        private

        def get_flow(flow_name)
          path = flow_definition_path(flow_name)
          SyncTraverse::Flow.new(File.exist?(path) ? JSON.parse(File.read(path)) : {})
        end

        def flow_definition_path(flow_name)
          File.join(flow_path(flow_name), "definition.json")
        end

        def flow_diagram_path(flow_name)
          File.join(flow_path(flow_name), "diagram.mmd")
        end

        def flows_dir
          SyncTraverse.config.flows_dir
        end

        def flow_path(flow_name)
          File.join(flows_dir, flow_name)
        end

        def write_file(path, content)
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, content)
        end

        def text_response(message)
          MCP::Tool::Response.new([{ type: "text", text: message }])
        end

        def error_response(message)
          MCP::Tool::Response.new([{ type: "text", text: message }], error: true)
        end

        def with_input_validation(flow_name: nil, node_names: [], file_names: [])
          invalid_names = [flow_name, *node_names].compact.uniq.grep_v(NAME_PATTERN)
          return error_response("Invalid name(s): #{invalid_names.join(", ")}") if invalid_names.any?

          invalid_files = file_names.uniq.grep_v(FILE_PATTERN)
          return error_response("Invalid file name(s): #{invalid_files.join(", ")}") if invalid_files.any?

          yield
        end
      end
    end
  end
end
