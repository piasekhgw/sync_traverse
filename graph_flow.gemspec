require_relative "lib/graph_flow/version"

Gem::Specification.new do |spec|
  spec.name = "graph_flow"
  spec.version = GraphFlow::VERSION
  spec.summary = "Minimal Ruby gem"
  spec.description = "A minimal Ruby gem skeleton for GraphFlow."
  spec.authors = ["Your Name"]
  spec.email = ["you@example.com"]
  spec.homepage = "https://example.com/graph_flow"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.add_dependency "rgl", ">= 0.6.7"

  spec.files = Dir["lib/**/*.rb", "README.md", ".gitignore"]
  spec.require_paths = ["lib"]
end
