module SyncTraverse
  class Flow
    class ConflictError < StandardError; end

    def initialize(definition = {})
      @definition = definition
    end

    def to_h
      targets = definition.values.flat_map(&:values)
      start, rest = definition.partition { |action, _| !targets.include?(action) }
      (start + rest).to_h
    end

    def add_transitions(transitions)
      transitions.each do |transition|
        source, target, result = transition.values_at(:source, :target, :source_result)
        if definition[source]&.key?(result) && definition[source][result] != target
          raise ConflictError,
                "Result '#{result}' of action '#{source}' already targets '#{definition[source][result]}'; remove that transition first"
        end

        definition[source] ||= {}
        definition[target] ||= {} unless target.nil?
        definition[source][result] = target
      end
    end

    def remove_transitions(transitions)
      transitions.each do |transition|
        source, target, result = transition.values_at(:source, :target, :source_result)
        definition[source].delete(result)
        remove_action_if_isolated(source)
        remove_action_if_isolated(target) unless target.nil?
      end
    end

    private

    attr_reader :definition

    def remove_action_if_isolated(action)
      return if definition[action].any? || definition.each_value.any? { |targets| targets.value?(action) }

      definition.delete(action)
    end
  end
end
