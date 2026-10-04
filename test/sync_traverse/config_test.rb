require "test_helper"

module SyncTraverse
  class ConfigTest < Minitest::Test
    def setup
      @root_dir = Dir.mktmpdir("sync_traverse_config_test")
    end

    def teardown
      FileUtils.remove_entry(@root_dir)
    end

    def test_resolves_paths_relative_to_root_dir
      write_config("nodes_dir" => "app/nodes", "flows_dir" => "app/flows", "node_tests_dir" => "test/nodes")
      config = Config.new(@root_dir)

      assert_equal [File.join(@root_dir, "app/nodes"), File.join(@root_dir, "app/flows"), File.join(@root_dir, "test/nodes")],
                   [config.nodes_dir, config.flows_dir, config.node_tests_dir]
    end

    def test_raises_when_setting_is_missing
      write_config("nodes_dir" => "app/nodes")
      error = assert_raises(Config::Error) { Config.new(@root_dir) }

      assert_equal "sync_traverse.yml is missing: flows_dir, node_tests_dir", error.message
    end

    def test_raises_when_file_is_missing
      error = assert_raises(Config::Error) { Config.new(@root_dir) }

      assert_includes error.message, "run `sync_traverse install` first"
    end

    private

    def write_config(settings)
      File.write(File.join(@root_dir, Config::FILE_NAME), settings.to_yaml)
    end
  end
end
