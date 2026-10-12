module SyncTraverse
  class Flow
    class ConflictError < StandardError; end

    def initialize(graph = {})
      @graph = graph
    end

    def to_h
      graph
    end

    def add_edges(edges)
      edges.each do |edge|
        source, target, outcome = edge.values_at(:source, :target, :source_outcome)
        if graph[source]&.key?(outcome) && graph[source][outcome] != target
          raise ConflictError,
                "Outcome '#{outcome}' of node '#{source}' already targets '#{graph[source][outcome]}'; remove that edge first"
        end

        graph[source] ||= {}
        graph[target] ||= {} unless target.nil?
        graph[source][outcome] = target
      end
    end

    def remove_edges(edges)
      edges.each do |edge|
        source, target, outcome = edge.values_at(:source, :target, :source_outcome)
        graph[source].delete(outcome)
        remove_node_if_isolated(source)
        remove_node_if_isolated(target) unless target.nil?
      end
    end

    private

    attr_reader :graph

    def remove_node_if_isolated(node)
      return if graph[node].any? || graph.each_value.any? { |targets| targets.value?(node) }

      graph.delete(node)
    end
  end
end
