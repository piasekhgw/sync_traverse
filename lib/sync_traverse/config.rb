require "yaml"

module SyncTraverse
  class Config
    FILE_NAME = "sync_traverse.yml".freeze
    SETTINGS = %w[nodes_dir flows_dir node_tests_dir].freeze

    class Error < StandardError; end

    attr_reader :nodes_dir, :flows_dir, :node_tests_dir

    def initialize(root_dir = Dir.pwd)
      settings = load_settings(root_dir)
      missing_settings = SETTINGS.reject { |name| settings[name] }
      raise Error, "#{FILE_NAME} is missing: #{missing_settings.join(", ")}" if missing_settings.any?

      @nodes_dir, @flows_dir, @node_tests_dir = SETTINGS.map { |name| File.expand_path(settings[name], root_dir) }
    end

    private

    def load_settings(root_dir)
      path = File.join(root_dir, FILE_NAME)
      raise Error, "#{path} not found; run `sync_traverse install` first" unless File.file?(path)

      YAML.safe_load_file(path)
    end
  end

  class << self
    attr_writer :config

    def config
      @config ||= Config.new
    end
  end
end
