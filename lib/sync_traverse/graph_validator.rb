require "rgl/bidirectional_adjacency"
require "rgl/topsort"

module SyncTraverse
  class GraphValidator
    def initialize(flow_definition)
      @flow_definition = flow_definition
    end

    def call
      return [] if flow_definition.empty?

      [acyclic_error, source_node_error, *duplicate_target_errors].compact
    end

    private

    attr_reader :flow_definition

    def acyclic_error
      "Flow must be acyclic" unless graph.acyclic?
    end

    def source_node_error
      return if source_nodes.size == 1

      found = source_nodes.empty? ? "none" : source_nodes.join(", ")
      "Flow must have exactly one source node, found: #{found}"
    end

    def duplicate_target_errors
      flow_definition.flat_map do |node, outcomes|
        outcomes_by_target = outcomes.keys.group_by { |outcome| outcomes[outcome] }
        duplicates = outcomes_by_target.select { |_target, names| names.size > 1 }

        duplicates.map do |target, names|
          target_label = target.nil? ? "null" : "'#{target}'"
          "Node '#{node}' has multiple outcomes leading to #{target_label}: #{names.join(", ")}"
        end
      end
    end

    def source_nodes
      @source_nodes ||= graph.vertices.select { |vertex| graph.in_degree(vertex).zero? }
    end

    def graph
      @graph ||= RGL::BidirectionalAdjacencyGraph.new.tap do |graph|
        flow_definition.each do |source, outcomes|
          graph.add_vertex(source)
          outcomes.each_value { |target| graph.add_edge(source, target) unless target.nil? }
        end
      end
    end
  end
end
