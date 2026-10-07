module SyncTraverse
  class Config
    attr_reader :nodes_dir, :tests_dir, :flows_dir

    def initialize(root_dir = Dir.pwd)
      @nodes_dir = File.expand_path("app/nodes", root_dir)
      @tests_dir = File.expand_path("test/nodes", root_dir)
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
