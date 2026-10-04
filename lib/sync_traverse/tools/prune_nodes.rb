module SyncTraverse
  module Tools
    class PruneNodes < NodeCodeBase
      tool_name "prune_nodes"
      description "Deletes the code of all nodes that are not used by any flow. Call this after update_flow removed nodes from a flow."

      def self.call(server_context:)
        used_nodes = Dir.glob(File.join(SyncTraverse.config.flows_dir, "**", "definition.json")).flat_map do |path|
          JSON.parse(File.read(path)).keys
        end
        unused_paths = Dir.glob(File.join(nodes_dir, "**", "*.rb")).reject do |path|
          used_nodes.include?(path.delete_prefix("#{nodes_dir}/").delete_suffix(".rb"))
        end

        FileUtils.rm_f(unused_paths)
        remove_empty_dirs(nodes_dir)

        text_response(unused_paths.empty? ? "ok" : "Removed:\n#{unused_paths.join("\n")}")
      end
    end
  end
end
