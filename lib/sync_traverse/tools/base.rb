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

        def flow_definition_path(flow_name)
          File.join(flows_dir, flow_name, "definition.json")
        end

        def flow_diagram_path(flow_name)
          File.join(flows_dir, flow_name, "definition.mmd")
        end

        def read_file(path)
          File.read(path, encoding: Encoding::UTF_8)
        end

        def read_json(path)
          JSON.parse(read_file(path))
        rescue JSON::ParserError
          raise CorruptedFileError, "File #{path} is not valid JSON; fix it or restore it from git"
        end

        def write_file(path, content)
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, content)
        end

        def delete_file(path, *roots)
          FileUtils.rm_f(path)

          dir = File.dirname(path)
          while roots.any? { |root| dir.start_with?("#{root}/") } && Dir.empty?(dir)
            Dir.rmdir(dir)
            dir = File.dirname(dir)
          end
        end

        def dir_file_names(dir)
          Dir.glob(File.join(dir, "*")).select { |path| File.file?(path) }.map { |path| File.basename(path) }
        end

        def test_file?(file_name)
          file_name.match?(TEST_FILE_PATTERN)
        end

        def actions_dir
          SyncTraverse.config.actions_dir
        end

        def action_tests_dir
          SyncTraverse.config.action_tests_dir
        end

        def flows_dir
          SyncTraverse.config.flows_dir
        end

        def flow_tests_dir
          SyncTraverse.config.flow_tests_dir
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
