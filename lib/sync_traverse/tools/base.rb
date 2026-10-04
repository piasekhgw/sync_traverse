require "fileutils"

module SyncTraverse
  module Tools
    class Base < MCP::Tool
      NAME_PATTERN = %r{\A[a-z0-9_]+(/[a-z0-9_]+)*\z}

      class << self
        private

        def get_flow(flow_name)
          path = flow_definition_path(flow_name)
          SyncTraverse::Flow.new(File.exist?(path) ? JSON.parse(File.read(path)) : {})
        end

        def write_file(path, content)
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, content)
        end

        def remove_empty_dirs(root)
          Dir.glob(File.join(root, "**", "*/")).sort_by { |dir| -dir.length }.each do |dir|
            Dir.rmdir(dir) if Dir.empty?(dir)
          end
        end

        def text_response(message)
          MCP::Tool::Response.new([{ type: "text", text: message }])
        end

        def error_response(message)
          MCP::Tool::Response.new([{ type: "text", text: message }], error: true)
        end

        def with_input_validation(flow_name: nil, node_names: [])
          invalid_names = [flow_name, *node_names].compact.uniq.grep_v(NAME_PATTERN)
          return error_response("Invalid name(s): #{invalid_names.join(", ")}") if invalid_names.any?

          yield
        end
      end
    end
  end
end
