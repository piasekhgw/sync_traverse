require "mcp"

require_relative "graph_flow/version"

module GraphFlow
end

require_relative "graph_flow/flow"
require_relative "graph_flow/installer"
require_relative "graph_flow/tools/base"
require_relative "graph_flow/tools/get_flow"
require_relative "graph_flow/tools/add_single_node"
require_relative "graph_flow/tools/remove_single_node"
require_relative "graph_flow/tools/add_edges"
require_relative "graph_flow/tools/remove_edges"
require_relative "graph_flow/tools/get_node_code"
require_relative "graph_flow/tools/upsert_node_code"
require_relative "graph_flow/tools/remove_node_code"
