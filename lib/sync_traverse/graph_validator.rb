require "rgl/bidirectional_adjacency"
require "rgl/topsort"

module SyncTraverse
  class GraphValidator
    def initialize(flow)
      @flow = flow
    end

    def call
      return [] if flow.empty?

      [
        undefined_targets_error,
        actions_without_results_error,
        duplicate_end_results_error,
        acyclic_error,
        source_action_error
      ].compact
    end

    private

    attr_reader :flow

    def undefined_targets_error
      undefined_targets = flow.values.flat_map(&:values).compact.uniq - flow.keys
      return if undefined_targets.empty?

      "Target action(s) not defined in the flow: #{undefined_targets.join(", ")}"
    end

    def actions_without_results_error
      actions = flow.select { |_, results| results.empty? }.keys
      return if actions.empty?

      "Action(s) without results: #{actions.join(", ")}"
    end

    def duplicate_end_results_error
      end_results = flow.values.flat_map { |results| results.select { |_, target| target.nil? }.keys }
      duplicates = end_results.tally.select { |_, count| count > 1 }.keys
      return if duplicates.empty?

      "Result(s) ending the flow in more than one action: #{duplicates.join(", ")}"
    end

    def acyclic_error
      return if graph.acyclic?

      "Flow must be acyclic"
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
