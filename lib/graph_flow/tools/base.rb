require "fileutils"

module GraphFlow
  module Tools
    class Base < MCP::Tool
      class << self
        private

        def write_file(path, content)
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, content)
          true
        end

        def text_response(payload)
          MCP::Tool::Response.new([{ type: "text", text: JSON.pretty_generate(payload) }])
        end
      end
    end
  end
end
