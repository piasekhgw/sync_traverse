require 'rgl/bidirectional_adjacency'

module GraphFlow
  class Flow
    attr_reader :definition

    def initialize(definition = {})
      @definition = definition
      @rgl_graph = RGL::BidirectionalAdjacencyGraph.new

      definition.to_a.each do |source, targets_by_outcome|
        add_node(source)
        add_edges(targets_by_outcome.map { |outcome, target| [source, target, outcome] })
      end
    end

    def add_node(node)
      definition[node] ||= {}

      rgl_graph.add_vertex(node)
    end

    def remove_node(node)
      definition.delete(node)
      definition.each_value do |targets_by_outcome|
        targets_by_outcome.delete_if { |_, target| target == node }
      end

      rgl_graph.remove_vertex(node)
    end

    def add_edges(edges)
      edges.each do |edge|
        source, target, label = edge

        add_node(source)
        add_node(target)

        definition[source][label] = target

        rgl_graph.add_edge(source, target)
      end
    end

    def remove_edges(edges)
      edges.each do |edge|
        source, target, label = edge

        definition[source].delete(label)

        rgl_graph.remove_edge(source, target)

        remove_node_if_isolated(source)
        remove_node_if_isolated(target)
      end
    end

    private

    attr_reader :rgl_graph

    def remove_node_if_isolated(node)
      return if rgl_graph.out_degree(node).positive? || rgl_graph.in_degree(node).positive?

      remove_node(node)
    end
  end
end
