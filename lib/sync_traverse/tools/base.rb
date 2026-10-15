require "fileutils"

module SyncTraverse
  module Tools
    class Base < MCP::Tool
      NAME_PATTERN = %r{\A[a-z0-9_]+(/[a-z0-9_]+)*\z}
      FILE_PATTERN = /\A[a-z0-9_]+(\.[a-z0-9]+)+\z/
      TEST_FILE_PATTERN = /(\A|_)test\.rb\z/

      class CorruptedFileError < StandardError; end

      class << self
        private

        def get_flow(flow_name)
          path = current_flow_path(flow_name)
          SyncTraverse::Flow.new(File.exist?(path) ? read_json(path) : {}).to_h
        end

        def get_flows(flow_names)
          flow_names.to_h { |flow_name| [flow_name, get_flow(flow_name)] }
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
          phase = flow_phase(flow_name)
          File.join(flow_path(flow_name), "#{phase == "none" ? "stable" : phase}.json")
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
          Config::FLOW_PHASES.find { |phase| File.exist?(File.join(flow_path(flow_name), "#{phase}.json")) } || "none"
        end

        def flows_dir
          SyncTraverse.config.flows_dir
        end

        def flow_path(flow_name)
          File.join(flows_dir, flow_name)
        end

        # Files are always UTF-8, regardless of the locale the server process was started with.
        def read_file(path)
          File.read(path, encoding: Encoding::UTF_8)
        end

        def read_json(path)
          JSON.parse(read_file(path))
        rescue JSON::ParserError
          raise CorruptedFileError, "File #{path} is not valid JSON; fix it or restore it from git"
        end

        # Writes through a temporary file and a rename, so an interrupted write never leaves a truncated file.
        # The dot prefix hides the temporary file from directory listings.
        def write_file(path, content)
          FileUtils.mkdir_p(File.dirname(path))
          tmp = File.join(File.dirname(path), ".#{File.basename(path)}.tmp")
          File.write(tmp, content)
          File.rename(tmp, path)
        ensure
          FileUtils.rm_f(tmp) if tmp
        end

        def delete_file(path, *roots)
          FileUtils.rm_f(path)

          dir = File.dirname(path)
          while roots.any? { |root| dir.start_with?("#{root}/") } && Dir.empty?(dir)
            Dir.rmdir(dir)
            dir = File.dirname(dir)
          end
        end

        def directory_files(dir)
          Dir.glob(File.join(dir, "*")).filter_map do |path|
            File.basename(path) if File.file?(path)
          end
        end

        def test_file?(file)
          file.match?(TEST_FILE_PATTERN)
        end

        def flow_tests_dir
          SyncTraverse.config.flow_tests_dir
        end

        def flow_test_files(flow_name)
          directory_files(File.join(flow_tests_dir, flow_name)).select { |file| test_file?(file) }.sort
        end

        def flow_test_path(flow_name, file)
          File.join(flow_tests_dir, flow_name, file)
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
        rescue CorruptedFileError => e
          error_response(e.message)
        end
      end
    end
  end
end
