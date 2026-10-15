module SyncTraverse
  module Tools
    class ActionCodeBase < Base
      ENTRY_FILE = "action.rb".freeze

      class << self
        private

        def get_action_code(action_name)
          action_files(action_name).to_h { |file| [file, File.read(action_file_path(action_name, file))] }
        end

        def update_action_files(action_name, files)
          files.each do |file, code|
            path = action_file_path(action_name, file)
            code.nil? ? delete_file(path, actions_dir, action_tests_dir) : write_file(path, code)
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
          test_files = directory_files(File.join(action_tests_dir, action_name))

          (code_files + test_files).sort
        end

        def action_file_path(action_name, file)
          File.join(test_file?(file) ? action_tests_dir : actions_dir, action_name, file)
        end

        def actions_dir
          SyncTraverse.config.actions_dir
        end

        def action_tests_dir
          SyncTraverse.config.action_tests_dir
        end
      end
    end
  end
end
