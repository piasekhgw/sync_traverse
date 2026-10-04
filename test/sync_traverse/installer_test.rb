require "test_helper"

module SyncTraverse
  class InstallerTest < Minitest::Test
    PATHS = { nodes_dir: "app/nodes", flows_dir: "app/flows", node_tests_dir: "test/nodes" }.freeze

    def setup
      @root_dir = Dir.mktmpdir("sync_traverse_installer_test")
    end

    def teardown
      FileUtils.remove_entry(@root_dir)
    end

    def test_installs_copilot_target
      install("copilot")

      assert_path_exists File.join(@root_dir, ".mcp.json")
      assert_path_exists File.join(@root_dir, ".github", "agents", "sync_traverse.agent.md")
      assert_path_exists File.join(@root_dir, "AGENTS.md")
    end

    def test_installs_claude_target
      install("claude")

      assert_path_exists File.join(@root_dir, ".mcp.json")
      assert_path_exists File.join(@root_dir, ".claude", "agents", "sync_traverse.md")
      assert_path_exists File.join(@root_dir, "AGENTS.md")
    end

    def test_raises_for_unknown_target
      assert_raises(ArgumentError) { install("bogus") }
    end

    def test_writes_paths_to_config_file
      install("claude")

      assert_equal(
        { "nodes_dir" => "app/nodes", "flows_dir" => "app/flows", "node_tests_dir" => "test/nodes" },
        YAML.safe_load_file(File.join(@root_dir, "sync_traverse.yml"))
      )
    end

    def test_written_config_can_be_loaded
      install("claude")

      assert_equal File.join(File.realpath(@root_dir), "app/flows"), Config.new(File.realpath(@root_dir)).flows_dir
    end

    def test_mcp_json_has_no_path_configuration
      install("claude")

      server = JSON.parse(File.read(File.join(@root_dir, ".mcp.json"))).dig("mcpServers", "sync_traverse")

      assert_equal ["-lc", "bundle exec sync_traverse mcp"], server["args"]
      refute server.key?("env")
    end

    def test_does_not_duplicate_agents_md_section_on_reinstall
      install("claude")
      first_content = File.read(File.join(@root_dir, "AGENTS.md"))

      install("claude")
      second_content = File.read(File.join(@root_dir, "AGENTS.md"))

      assert_equal first_content, second_content
    end

    def test_appends_to_existing_agents_md
      File.write(File.join(@root_dir, "AGENTS.md"), "# My Project\n")

      install("claude")

      content = File.read(File.join(@root_dir, "AGENTS.md"))

      assert content.start_with?("# My Project")
      assert_includes content, "Sync Traverse"
    end

    private

    def install(target)
      capture_io { Installer.new.call(target, root_dir: @root_dir, **PATHS) }
    end
  end
end
