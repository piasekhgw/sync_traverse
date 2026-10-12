require "fileutils"

module SyncTraverse
  module Tools
    class Base < MCP::Tool
      NAME_PATTERN = %r{\A[a-z0-9_]+(/[a-z0-9_]+)*\z}
      FILE_PATTERN = /\A[a-z0-9_]+(\.[a-z0-9]+)+\z/

      class << self
        private

        def get_flow(flow_name)
          path = current_flow_path(flow_name)
          SyncTraverse::Flow.new(File.exist?(path) ? JSON.parse(File.read(path)) : {}).to_h
        end

        def flow_stable_path(flow_name)
          File.join(flow_path(flow_name), "stable.json")
        end

        def flow_draft_path(flow_name)
          File.join(flow_path(flow_name), "draft.json")
        end

        def flow_approved_path(flow_name)
          File.join(flow_path(flow_name), "approved.json")
        end

        def current_flow_path(flow_name)
          return flow_approved_path(flow_name) if approved?(flow_name)

          draft?(flow_name) ? flow_draft_path(flow_name) : flow_stable_path(flow_name)
        end

        def flow_stable_diagram_path(flow_name)
          File.join(flow_path(flow_name), "stable.mmd")
        end

        def flow_draft_diagram_path(flow_name)
          File.join(flow_path(flow_name), "draft.mmd")
        end

        def flow_approved_diagram_path(flow_name)
          File.join(flow_path(flow_name), "approved.mmd")
        end

        def draft?(flow_name)
          File.exist?(flow_draft_path(flow_name))
        end

        def approved?(flow_name)
          File.exist?(flow_approved_path(flow_name))
        end

        def stable?(flow_name)
          File.exist?(flow_stable_path(flow_name))
        end

        def flow_phase(flow_name)
          return "approved" if approved?(flow_name)

          draft?(flow_name) ? "draft" : "stable"
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

        def text_response(*messages)
          MCP::Tool::Response.new(messages.map { |message| { type: "text", text: message } })
        end

        def error_response(message)
          MCP::Tool::Response.new([{ type: "text", text: message }], error: true)
        end

        def with_valid_format(flow_names: [], action_names: [], file_names: [])
          invalid_names = [*flow_names, *action_names].compact.uniq.grep_v(NAME_PATTERN)
          return error_response("Invalid name(s): #{invalid_names.join(", ")}") if invalid_names.any?

          invalid_files = file_names.uniq.grep_v(FILE_PATTERN)
          return error_response("Invalid file name(s): #{invalid_files.join(", ")}") if invalid_files.any?

          yield
        end
      end
    end
  end
end
