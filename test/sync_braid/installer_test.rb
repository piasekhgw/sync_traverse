require "test_helper"

module SyncBraid
  class InstallerTest < Minitest::Test
    def setup
      @root_dir = Dir.mktmpdir("sync_braid_installer_test")
    end

    def teardown
      FileUtils.remove_entry(@root_dir)
    end

    def test_installs_copilot_target
      Installer.new.call("copilot", root_dir: @root_dir)

      assert_path_exists File.join(@root_dir, ".mcp.json")
      assert_path_exists File.join(@root_dir, ".github", "agents", "sync_braid.agent.md")
      assert_path_exists File.join(@root_dir, "AGENTS.md")
    end

    def test_installs_claude_target
      Installer.new.call("claude", root_dir: @root_dir)

      assert_path_exists File.join(@root_dir, ".mcp.json")
      assert_path_exists File.join(@root_dir, ".claude", "agents", "sync_braid.md")
      assert_path_exists File.join(@root_dir, "AGENTS.md")
    end

    def test_raises_for_unknown_target
      assert_raises(ArgumentError) { Installer.new.call("bogus", root_dir: @root_dir) }
    end

    def test_does_not_duplicate_agents_md_section_on_reinstall
      Installer.new.call("claude", root_dir: @root_dir)
      first_content = File.read(File.join(@root_dir, "AGENTS.md"))

      Installer.new.call("claude", root_dir: @root_dir)
      second_content = File.read(File.join(@root_dir, "AGENTS.md"))

      assert_equal first_content, second_content
    end

    def test_appends_to_existing_agents_md
      File.write(File.join(@root_dir, "AGENTS.md"), "# My Project\n")

      Installer.new.call("claude", root_dir: @root_dir)

      content = File.read(File.join(@root_dir, "AGENTS.md"))

      assert content.start_with?("# My Project")
      assert_includes content, "Sync Braid"
    end
  end
end
