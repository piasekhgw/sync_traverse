module SyncTraverse
  module Tools
    class ActionCodeBase < Base
      ENTRY_FILE = "action.rb".freeze
      TEST_FILE_PATTERN = /(\A|_)test\.rb\z/

      class << self
        private

        def get_action_code(action_name)
          action_files(action_name).to_h { |file| [file, File.read(action_file_path(action_name, file))] }
        end

        def update_action_files(action_name, files)
          files.each do |file, code|
            path = action_file_path(action_name, file)
            code.nil? ? delete_action_file(path) : write_file(path, code)
          end
        end

        def delete_action_file(path)
          FileUtils.rm_f(path)

          dir = File.dirname(path)
          while [actions_dir, tests_dir].any? { |root| dir.start_with?("#{root}/") } && Dir.empty?(dir)
            Dir.rmdir(dir)
            dir = File.dirname(dir)
          end
        end

        def remaining_action_files(action_name, files)
          deleted = files.select { |_, code| code.nil? }.keys
          written = files.compact.keys

          (action_files(action_name) | written) - deleted
        end

        def flows_using_action(action_name)
          Dir.glob(File.join(flows_dir, "**", "{stable,draft,approved}.json")).filter_map do |path|
            File.dirname(path).delete_prefix("#{flows_dir}/") if JSON.parse(File.read(path)).key?(action_name)
          end.uniq.sort
        end

        def action_files(action_name)
          code_files = directory_files(File.join(actions_dir, action_name))
          test_files = directory_files(File.join(tests_dir, action_name))

          (code_files + test_files).sort
        end

        def directory_files(dir)
          Dir.glob(File.join(dir, "*")).filter_map do |path|
            File.basename(path) if File.file?(path)
          end
        end

        def test_file?(file)
          file.match?(TEST_FILE_PATTERN)
        end

        def action_file_path(action_name, file)
          File.join(test_file?(file) ? tests_dir : actions_dir, action_name, file)
        end

        def actions_dir
          SyncTraverse.config.actions_dir
        end

        def tests_dir
          SyncTraverse.config.tests_dir
        end
      end
    end
  end
end
