module SyncTraverse
  class Config
    attr_reader :nodes_dir, :flows_dir, :node_tests_dir

    def initialize
      @nodes_dir = ENV.fetch("SYNC_TRAVERSE_NODES_DIR")
      @flows_dir = ENV.fetch("SYNC_TRAVERSE_FLOWS_DIR")
      @node_tests_dir = ENV.fetch("SYNC_TRAVERSE_NODE_TESTS_DIR")
    end
  end

  class << self
    def config
      @config ||= Config.new
    end
  end
end
