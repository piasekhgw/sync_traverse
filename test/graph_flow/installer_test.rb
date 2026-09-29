require "test_helper"

module GraphFlow
  class InstallerTest < Minitest::Test
    def setup
      @root_dir = Dir.mktmpdir("graph_flow_installer_test")
    end

    def teardown
      FileUtils.remove_entry(@root_dir)
    end

    def test_installs_copilot_target
      Installer.new.run("copilot", root_dir: @root_dir)

      assert File.exist?(File.join(@root_dir, ".mcp.json"))
      assert File.exist?(File.join(@root_dir, ".github", "agents", "graph.agent.md"))
      assert File.exist?(File.join(@root_dir, "AGENTS.md"))
    end

    def test_installs_claude_target
      Installer.new.run("claude", root_dir: @root_dir)

      assert File.exist?(File.join(@root_dir, ".mcp.json"))
      assert File.exist?(File.join(@root_dir, ".claude", "agents", "graph.md"))
      assert File.exist?(File.join(@root_dir, "AGENTS.md"))
    end

    def test_raises_for_unknown_target
      assert_raises(ArgumentError) { Installer.new.run("bogus", root_dir: @root_dir) }
    end

    def test_does_not_duplicate_agents_md_section_on_reinstall
      Installer.new.run("claude", root_dir: @root_dir)
      first_content = File.read(File.join(@root_dir, "AGENTS.md"))

      Installer.new.run("claude", root_dir: @root_dir)
      second_content = File.read(File.join(@root_dir, "AGENTS.md"))

      assert_equal first_content, second_content
    end

    def test_appends_to_existing_agents_md
      File.write(File.join(@root_dir, "AGENTS.md"), "# My Project\n")

      Installer.new.run("claude", root_dir: @root_dir)

      content = File.read(File.join(@root_dir, "AGENTS.md"))
      assert content.start_with?("# My Project")
      assert_includes content, "Graph Flow"
    end
  end
end
