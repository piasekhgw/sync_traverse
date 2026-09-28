require "erb"
require "fileutils"

module GraphFlow
  class Installer
    GEM_ROOT = File.expand_path("../..", __dir__)
    TEMPLATES_DIR = File.join(GEM_ROOT, "templates")
    PROMPT_PATH = File.join(GEM_ROOT, "prompts", "flow_agent.md")

    TARGETS = {
      File.join(TEMPLATES_DIR, ".mcp.json") => ".mcp.json",
      File.join(TEMPLATES_DIR, "agents", "github.agent.md.erb") => File.join(".github", "agents", "graph.agent.md"),
      File.join(TEMPLATES_DIR, "agents", "claude.md.erb") => File.join(".claude", "agents", "graph.md")
    }.freeze

    def run(root_dir: Dir.pwd)
      body = File.read(PROMPT_PATH)

      TARGETS.each do |template_path, relative_target|
        target_path = File.join(root_dir, relative_target)
        content = render(template_path, body)

        FileUtils.mkdir_p(File.dirname(target_path))
        File.write(target_path, content)
        puts "#{relative_target} created"
      end
    end

    private

    def render(template_path, body)
      return File.read(template_path) unless template_path.end_with?(".erb")

      ERB.new(File.read(template_path)).result_with_hash(body: body)
    end
  end
end
