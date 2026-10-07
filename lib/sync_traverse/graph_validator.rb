require "rgl/bidirectional_adjacency"
require "rgl/topsort"

module SyncTraverse
  class GraphValidator
    def initialize(flow_definition)
      @flow_definition = flow_definition
    end

    def call
      return [] if flow_definition.empty?

      [acyclic_error, source_node_error].compact
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
