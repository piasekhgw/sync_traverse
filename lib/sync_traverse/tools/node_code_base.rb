module SyncTraverse
  module Tools
    class NodeCodeBase < Base
      ENTRY_FILE = "node.rb".freeze
      TEST_FILE_PATTERN = /(\A|_)test\.rb\z/

      class << self
        private

        def get_node_code(node_name)
          node_files(node_name).to_h { |file| [file, File.read(node_file_path(node_name, file))] }
        end

        def update_node_files(node_name, files)
          files.each do |file, code|
            path = node_file_path(node_name, file)
            code.nil? ? delete_node_file(path) : write_file(path, code)
          end
        end

        def delete_node_file(path)
          FileUtils.rm_f(path)

          dir = File.dirname(path)
          while [nodes_dir, tests_dir].any? { |root| dir.start_with?("#{root}/") } && Dir.empty?(dir)
            Dir.rmdir(dir)
            dir = File.dirname(dir)
          end
        end

        def remaining_node_files(node_name, files)
          deleted = files.select { |_, code| code.nil? }.keys
          written = files.compact.keys

          (node_files(node_name) | written) - deleted
        end

        def flows_using_node(node_name)
          Dir.glob(File.join(flows_dir, "**", "definition.json")).filter_map do |path|
            File.dirname(path).delete_prefix("#{flows_dir}/") if JSON.parse(File.read(path)).key?(node_name)
          end.sort
        end

        def node_files(node_name)
          code_files = directory_files(File.join(nodes_dir, node_name))
          test_files = directory_files(File.join(tests_dir, node_name))

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

        def node_file_path(node_name, file)
          File.join(test_file?(file) ? tests_dir : nodes_dir, node_name, file)
        end

        def nodes_dir
          SyncTraverse.config.nodes_dir
        end

        def tests_dir
          SyncTraverse.config.tests_dir
        end
      end
    end
  end
end
