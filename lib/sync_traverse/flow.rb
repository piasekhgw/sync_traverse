module SyncTraverse
  class Flow
    class ConflictError < StandardError; end

    def initialize(graph = {})
      @graph = graph
    end

    def to_h
      graph
    end

    def add_transitions(transitions)
      transitions.each do |transition|
        source, target, result = transition.values_at(:source, :target, :source_result)
        if graph[source]&.key?(result) && graph[source][result] != target
          raise ConflictError,
                "Result '#{result}' of action '#{source}' already targets '#{graph[source][result]}'; remove that transition first"
        end

        graph[source] ||= {}
        graph[target] ||= {} unless target.nil?
        graph[source][result] = target
      end
    end

    def remove_transitions(transitions)
      transitions.each do |transition|
        source, target, result = transition.values_at(:source, :target, :source_result)
        graph[source].delete(result)
        remove_action_if_isolated(source)
        remove_action_if_isolated(target) unless target.nil?
      end
    end

    private

    attr_reader :graph

    def remove_action_if_isolated(action)
      return if graph[action].any? || graph.each_value.any? { |targets| targets.value?(action) }

      graph.delete(action)
    end
  end
end
