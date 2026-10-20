require_relative "lib/sync_traverse/version"

Gem::Specification.new do |spec|
  spec.name = "sync_traverse"
  spec.version = SyncTraverse::VERSION
  spec.summary = "Experimental MCP server and agent prompt for explicit, graph-based synchronous flows in Rails apps"
  spec.description = <<~TEXT.tr("\n", " ").strip
    SyncTraverse is an experimental research prototype, not intended for production use.
    It lets an AI coding agent (GitHub Copilot or Claude Code) design and refactor synchronous
    application processes as explicit directed acyclic graphs of small, isolated actions.
    The agent changes flows and actions only through a Model Context Protocol (MCP) server that
    validates graph invariants, checks action result contracts and runs action and flow tests.
  TEXT
  spec.authors = ["Wojciech Piasecki"]
  spec.homepage = "https://github.com/piasekhgw/sync_traverse"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  # Not published to RubyGems yet; remove this line to allow `gem push`.
  spec.metadata["allowed_push_host"] = "https://example.invalid"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.add_dependency "activesupport", ">= 6.1"
  spec.add_dependency "mcp", ">= 1.0.0"
  spec.add_dependency "minitest", ">= 5.1"
  spec.add_dependency "rgl", ">= 0.5.0"

  spec.files = Dir.glob(["lib/**/*.rb", "templates/**/*", "prompts/**/*", "exe/*"], File::FNM_DOTMATCH)
                  .select { |path| File.file?(path) } + ["README.md", "LICENSE.txt"]
  spec.bindir = "exe"
  spec.executables = ["sync_traverse"]
  spec.require_paths = ["lib"]
end
