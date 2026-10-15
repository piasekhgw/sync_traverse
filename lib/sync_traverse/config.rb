module SyncTraverse
  class Config
    # Graph file phases of a flow (<phase>.json), from the one used first.
    FLOW_PHASES = %w[approved draft stable].freeze

    attr_reader :root_dir, :actions_dir, :action_tests_dir, :flows_dir, :flow_tests_dir

    # Phases the Runner looks for in a flow directory, first existing wins. Only stable by default,
    # the tests runner widens it so that flow tests run the graph being implemented.
    attr_accessor :flow_phases

    def initialize(root_dir = Dir.pwd)
      @root_dir = root_dir
      @actions_dir = File.expand_path("app/actions", root_dir)
      @action_tests_dir = File.expand_path("test/actions", root_dir)
      @flows_dir = File.expand_path("app/flows", root_dir)
      @flow_tests_dir = File.expand_path("test/flows", root_dir)
      @flow_phases = %w[stable]
    end
  end

  class << self
    attr_writer :config

    def config
      @config ||= Config.new
    end
  end
end
