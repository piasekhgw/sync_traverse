require_relative "lib/sync_traverse/version"

Gem::Specification.new do |spec|
  spec.name = "sync_traverse"
  spec.version = SyncTraverse::VERSION
  spec.summary = "Minimal Ruby gem"
  spec.description = "A minimal Ruby gem skeleton for SyncTraverse."
  spec.authors = ["Your Name"]
  spec.email = ["you@example.com"]
  spec.homepage = "https://example.com/sync_traverse"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.add_dependency "activesupport", ">= 6.1"
  spec.add_dependency "mcp", ">= 1.0.0"
  spec.add_dependency "minitest", ">= 5.1"
  spec.add_dependency "rgl", ">= 0.5.0"

  spec.files = Dir["lib/**/*.rb", "templates/**/*", "prompts/**/*", "exe/*", "README.md", ".gitignore"]
  spec.bindir = "exe"
  spec.executables = ["sync_traverse"]
  spec.require_paths = ["lib"]
end
