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
      action_name = start_action(flow)
      result = nil

      while action_name
        result = run_action(action_name, context).to_s
        action_name = flow.fetch(action_name).fetch(result)
      end

      result
    end

    private

    attr_reader :flow

    def load_flow(flow_name)
      JSON.parse(File.read(File.join(SyncTraverse.config.flows_dir, flow_name, "stable.json")))
    end

    def start_action(flow)
      targets = flow.values.flat_map(&:values)
      flow.keys.detect { |action| !targets.include?(action) }
    end

    def run_action(action_name, context)
      action_class(action_name).call(context)
    end

    def action_class(action_name)
      "#{action_name}/action".camelize.constantize
    end
  end
end
