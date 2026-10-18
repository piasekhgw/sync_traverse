module SyncTraverse
  class Config
    attr_reader :root_dir, :actions_dir, :action_tests_dir, :flows_dir, :flow_tests_dir

    def initialize(root_dir = Dir.pwd)
      @root_dir = root_dir
      @actions_dir = File.expand_path("app/actions", root_dir)
      @action_tests_dir = File.expand_path("test/actions", root_dir)
      @flows_dir = File.expand_path("app/flows", root_dir)
      @flow_tests_dir = File.expand_path("test/flows", root_dir)
    end
  end

  class << self
    attr_writer :config

    def config
      @config ||= Config.new
    end
  end
end
