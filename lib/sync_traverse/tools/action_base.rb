module SyncTraverse
  module Tools
    class ActionBase < Base
      ACTION_NAME_SCHEMA = {
        type: "string",
        description: "The action name in snake_case. Must be a relative path; may be namespaced with a path, for example 'orders/validate_order'."
      }.freeze

      class << self
        private

        def read_action_files(action_name)
          { files: read_files(action_dir(action_name)), test_files: read_files(action_test_dir(action_name)) }
        end

        def write_action_files(action_name, files, test_files)
          write_files(action_dir(action_name), files, actions_dir)
          write_files(action_test_dir(action_name), test_files, action_tests_dir)
        end

        def action_dir(action_name)
          File.join(actions_dir, action_name)
        end

        def action_test_dir(action_name)
          File.join(action_tests_dir, action_name)
        end

        def read_files(dir)
          dir_file_names(dir).sort.to_h { |file_name| [file_name, read_file(File.join(dir, file_name))] }
        end

        def write_files(dir, files, root)
          files.each do |file_name, content|
            path = File.join(dir, file_name)
            content.nil? ? delete_file(path, root) : write_file(path, content)
          end
        end
      end
    end
  end
end
