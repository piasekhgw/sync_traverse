module GraphFlow
  module Tools
    class FlowBase < Base
      EDGE_SCHEMA = {
        type: "object",
        properties: {
          source: { type: "string", description: "Source node name." },
          target: { type: ["string", "null"], description: "Target node name, or null if this outcome ends the flow." },
          source_outcome: { type: "string", description: "Outcome returned by the source node that selects this edge." }
        },
        required: ["source", "target", "source_outcome"]
      }.freeze

      class << self
        private

        def get_flow(flow_name)
          path = flow_path(flow_name)
          GraphFlow::Flow.new(File.exist?(path) ? JSON.parse(File.read(path)) : {})
        end

        def save_flow(flow_name, flow)
          write_file(flow_path(flow_name), JSON.pretty_generate(flow.definition))
        end

        def flow_path(flow_name)
          File.join(flows_dir, flow_name, "definition.json")
        end

        def edge_node_names(edges)
          edges.flat_map { |edge| edge.values_at(:source, :target) }
        end

        def flows_dir
          GraphFlow.config.flows_dir
        end
      end
    end
  end
end
