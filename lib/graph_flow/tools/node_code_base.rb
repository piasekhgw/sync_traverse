module GraphFlow
  module Tools
    class NodeCodeBase < Base
      class << self
        private

        def get_node_code(node_name)
          path = node_path(node_name)
          File.exist?(path) ? File.read(path) : nil
        end

        def update_node_code(node_name, code)
          write_file(node_path(node_name), code)
        end

        # TODO: Validate that node_name does not escape nodes_dir (e.g. via "../").
        def node_path(node_name)
          File.join(nodes_dir, "#{node_name}.rb")
        end

        def nodes_dir
          'nodes' # TODO: Replace with a configuration variable
        end
      end
    end
  end
end
