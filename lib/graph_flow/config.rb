module GraphFlow
  class Config
    attr_accessor :nodes_dir, :flows_dir, :node_tests_dir

    def initialize
      @nodes_dir = "nodes"
      @flows_dir = "flows"
      @node_tests_dir = "test/nodes"
    end
  end

  class << self
    def config
      @config ||= Config.new
    end

    def configure
      yield config
    end
  end
end
