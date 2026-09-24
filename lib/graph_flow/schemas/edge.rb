require "schematist"

module GraphFlow
  module Schemas
    class Edge < Schematist::Schema
      string :source, description: "Source node name."
      string :target, description: "Target node name."
      string :source_outcome, description: "Outcome returned by the source node that selects this edge."
    end
  end
end
