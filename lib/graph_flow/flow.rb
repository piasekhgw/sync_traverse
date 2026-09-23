require 'rgl/bidirectional_adjacency'

module GraphFlow
  class Flow
    attr_reader :transitions

    def self.create_for_single_node(node_class_name)
      new(
        { node_class_name => {} },
        RGL::BidirectionalAdjacencyGraph.new.tap {|graph| graph.add_vertex(node_class_name) }
      )
    end

    def initialize(transitions = {}, rgl_graph = nil)
      @transitions = transitions
      @rgl_graph = rgl_graph || RGL::BidirectionalAdjacencyGraph[*rgl_graph_edges]
    end

    def add_edges(edges)
      edges.each do |edge|
        source, target, label = edge

        transitions[source] ||= {}
        transitions[source][label] = target

        rgl_graph.add_edge(source, target)
      end
    end

    def remove_edges(edges)
      edges.each do |edge|
        source, target, label = edge

        if transitions.key?(source)
          transitions[source].delete(label)
          transitions.delete(source) if transitions[source].empty?
        end

        rgl_graph.remove_edge(source, target)
        remove_rgl_vertex_if_isolated(source)
        remove_rgl_vertex_if_isolated(target)
      end
    end

    private

    attr_reader :rgl_graph

    def rgl_graph_edges
      transitions.flat_map do |source_node_class_name, target_nodes_by_outcome|
        [source_node_class_name].product(target_nodes_by_outcome.values)
      end
    end

    def remove_rgl_vertex_if_isolated(vertex)
      return if rgl_graph.out_degree(vertex).positive? || rgl_graph.in_degree(vertex).positive?

      rgl_graph.remove_vertex(vertex)
    end
  end
end
