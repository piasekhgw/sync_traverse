require "rgl/bidirectional_adjacency"
require "rgl/topsort"

module SyncTraverse
  class GraphValidator
    def initialize(flow)
      @flow = flow
    end

    def call
      return [] if flow.empty?

      [acyclic_error, source_action_error].compact
    end

    private

    attr_reader :flow

    def acyclic_error
      "Flow must be acyclic" unless graph.acyclic?
    end

    def source_action_error
      return if source_actions.size == 1

      found = source_actions.empty? ? "none" : source_actions.join(", ")
      "Flow must have exactly one source action, found: #{found}"
    end

    def source_actions
      @source_actions ||= graph.vertices.select { |vertex| graph.in_degree(vertex).zero? }
    end

    def graph
      @graph ||= RGL::BidirectionalAdjacencyGraph.new.tap do |graph|
        flow.each do |source, results|
          graph.add_vertex(source)
          results.each_value { |target| graph.add_edge(source, target) unless target.nil? }
        end
      end
    end
  end
end
