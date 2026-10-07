module SyncTraverse
  module Tools
    class FlowBase < Base
      EDGE_SCHEMA = {
        type: "object",
        properties: {
          source: { type: "string", description: "Source node name." },
          target: { type: %w[string null], description: "Target node name, or null if this outcome ends the flow." },
          source_outcome: { type: "string", description: "Outcome returned by the source node that selects this edge." }
        },
        required: %w[source target source_outcome]
      }.freeze

      class << self
        private

        def save_flow(flow_name, flow)
          write_file(flow_definition_path(flow_name), JSON.pretty_generate(flow.definition))
        end

        def delete_flow(flow_name)
          path = flow_path(flow_name)
          FileUtils.rm_rf(path)

          dir = File.dirname(path)
          while dir.start_with?("#{flows_dir}/") && Dir.empty?(dir)
            Dir.rmdir(dir)
            dir = File.dirname(dir)
          end
        end

        def edge_node_names(edges)
          edges.flat_map { |edge| edge.values_at(:source, :target) }
        end
      end
    end
  end
end
