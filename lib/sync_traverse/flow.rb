module SyncTraverse
  class Flow
    def initialize(definition = {})
      @definition = definition
    end

    def to_h
      targets = definition.values.flat_map(&:values)
      start, rest = definition.partition { |action, _| !targets.include?(action) }
      (start + rest).to_h
    end

    # Mermaid flowchart: transitions labeled with results, every null target a separate end node.
    def to_mermaid
      ends = 0
      nodes = to_h.keys.map { |action| "  #{action}[#{action}]" }
      edges = to_h.flat_map do |action, results|
        results.map { |result, target| "  #{action} -->|#{result}| #{target || "end#{ends += 1}((End))"}" }
      end

      "#{["flowchart TD", *nodes, *edges].join("\n")}\n"
    end

    private

    attr_reader :definition
  end
end
