require "json"
require "active_support/core_ext/string/inflections"

module SyncTraverse
  class Runner
    def self.call(flow_name, context = {})
      new(flow_name).call(context)
    end

    def initialize(flow_name)
      @flow = load_flow(flow_name)
    end

    def call(context = {})
      node_name = start_node(flow)

      while node_name
        outcome = run_node(node_name, context)
        node_name = flow.fetch(node_name).fetch(outcome.to_s)
      end

      context
    end

    private

    attr_reader :flow

    def load_flow(flow_name)
      JSON.parse(File.read(File.join(SyncTraverse.config.flows_dir, flow_name, "definition.json")))
    end

    def start_node(flow)
      targets = flow.values.flat_map(&:values)
      flow.keys.detect { |node| !targets.include?(node) }
    end

    def run_node(node_name, context)
      node_class(node_name).call(context)
    end

    def node_class(node_name)
      "#{node_name}/node".camelize.constantize
    end
  end
end
