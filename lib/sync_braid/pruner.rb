require "json"

module SyncBraid
  class Pruner
    def call
      definitions = Dir.glob(File.join(flows_dir, "**", "definition.json")).to_h do |path|
        [path, JSON.parse(File.read(path))]
      end
      used_nodes = definitions.values.flat_map(&:keys)

      empty_flow_paths = definitions.select { |_, definition| definition.empty? }.keys
      unused_node_paths = Dir.glob(File.join(nodes_dir, "**", "*.rb")).reject do |path|
        used_nodes.include?(path.delete_prefix("#{nodes_dir}/").delete_suffix(".rb"))
      end

      (empty_flow_paths + unused_node_paths).each do |path|
        File.delete(path)
        puts "removed #{path}"
      end

      remove_empty_dirs(flows_dir)
      remove_empty_dirs(nodes_dir)
    end

    private

    def remove_empty_dirs(root)
      Dir.glob(File.join(root, "**", "*/")).sort_by { |dir| -dir.length }.each do |dir|
        Dir.rmdir(dir) if Dir.empty?(dir)
      end
    end

    def flows_dir
      SyncBraid.config.flows_dir
    end

    def nodes_dir
      SyncBraid.config.nodes_dir
    end
  end
end
