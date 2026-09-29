require "erb"
require "fileutils"

module GraphFlow
  class Installer
    GEM_ROOT = File.expand_path("../..", __dir__)
    TEMPLATES_DIR = File.join(GEM_ROOT, "templates")
    PROMPT_PATH = File.join(GEM_ROOT, "prompts", "flow_agent.md")
    AGENTS_SECTION_PATH = File.join(TEMPLATES_DIR, "agents_section.md")

    AGENT_TEMPLATES = {
      "copilot" => [File.join(TEMPLATES_DIR, "agents", "github.agent.md.erb"), File.join(".github", "agents", "graph.agent.md")],
      "claude" => [File.join(TEMPLATES_DIR, "agents", "claude.md.erb"), File.join(".claude", "agents", "graph.md")]
    }.freeze

    def run(target, root_dir: Dir.pwd)
      template_path, relative_target = AGENT_TEMPLATES[target]
      raise ArgumentError, "Unknown target '#{target}', expected one of: #{AGENT_TEMPLATES.keys.join(', ')}" unless template_path

      write_file(root_dir, ".mcp.json", File.read(File.join(TEMPLATES_DIR, ".mcp.json")))
      write_file(root_dir, relative_target, render(template_path))
      update_agents_md(root_dir)
    end

    private

    def render(template_path)
      ERB.new(File.read(template_path)).result_with_hash(body: File.read(PROMPT_PATH))
    end

    def write_file(root_dir, relative_path, content)
      target_path = File.join(root_dir, relative_path)
      FileUtils.mkdir_p(File.dirname(target_path))
      File.write(target_path, content)
      puts "#{relative_path} created"
    end

    def update_agents_md(root_dir)
      path = File.join(root_dir, "AGENTS.md")
      section = File.read(AGENTS_SECTION_PATH)
      existing = File.exist?(path) ? File.read(path) : nil
      return if existing&.include?(section)

      File.write(path, existing ? "#{existing.chomp}\n\n#{section}" : section)
      puts "AGENTS.md updated"
    end
  end
end
