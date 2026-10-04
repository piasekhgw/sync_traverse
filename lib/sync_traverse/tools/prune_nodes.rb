module SyncTraverse
  module Tools
    class PruneNodes < NodeCodeBase
      tool_name "prune_nodes"
      description "Deletes the code and tests of all nodes that are not used by any flow. Call this after update_flow removed nodes from a flow."

      class << self
        def call(server_context:)
          used_nodes = Dir.glob(File.join(SyncTraverse.config.flows_dir, "**", "definition.json")).flat_map do |path|
            JSON.parse(File.read(path)).keys
          end
          unused_nodes = Dir.glob(File.join(nodes_dir, "**", "*.rb")).map do |path|
            path.delete_prefix("#{nodes_dir}/").delete_suffix(".rb")
          end - used_nodes

          unused_nodes.each do |node|
            FileUtils.rm_f([node_path(node), *Dir.glob(File.join(node_tests_dir, "#{node}_{test,spec}.rb"))])
          end
          remove_empty_dirs(nodes_dir)
          remove_empty_dirs(node_tests_dir)

          text_response(unused_nodes.empty? ? "Success" : "Removed code and tests of nodes: #{unused_nodes.join(", ")}")
        end

        private

        def node_tests_dir
          SyncTraverse.config.node_tests_dir
        end
      end
    end
  end
end
