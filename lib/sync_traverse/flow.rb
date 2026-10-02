module SyncTraverse
  class Flow
    class ConflictError < StandardError; end

    attr_reader :definition

    def initialize(definition = {})
      @definition = definition
    end

    def add_edges(edges)
      edges.each do |edge|
        source, target, outcome = edge.values_at(:source, :target, :source_outcome)
        if definition[source]&.key?(outcome) && definition[source][outcome] != target
          raise ConflictError,
                "Outcome '#{outcome}' of node '#{source}' already targets '#{definition[source][outcome]}'; remove that edge first"
        end

        definition[source] ||= {}
        definition[target] ||= {} unless target.nil?
        definition[source][outcome] = target
      end
    end

    def remove_edges(edges)
      edges.each do |edge|
        source, target, outcome = edge.values_at(:source, :target, :source_outcome)
        definition[source].delete(outcome)
        remove_node_if_isolated(source)
        remove_node_if_isolated(target) unless target.nil?
      end
    end

    private

    def remove_node_if_isolated(node)
      return if definition[node].any? || definition.each_value.any? { |targets| targets.value?(node) }

      definition.delete(node)
    end
  end
end
