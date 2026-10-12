module SyncTraverse
  class Config
    attr_reader :actions_dir, :tests_dir, :flows_dir

    def initialize(root_dir = Dir.pwd)
      @actions_dir = File.expand_path("app/actions", root_dir)
      @tests_dir = File.expand_path("test/actions", root_dir)
      @flows_dir = File.expand_path("app/flows", root_dir)
    end
  end

  class << self
    attr_writer :config

    def config
      @config ||= Config.new
    end
  end
end
