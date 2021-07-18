# frozen_string_literal : true
module TraceGraph
  # Module is for validation in general
  # As of now has validations for trace path and nodes
  # Going forward main validations will move here
  module Validators
    def validate_trace_path(call_graph, source, dest)
      # validate if the source node has outward nodes
      # validate if the destination node has inward nodes
      check_outward_nodes(call_graph, source) && check_inward_node(call_graph, dest)
    end

    # check if there exists nodes that are going from the source or not
    # method checks if there exists a key in the call hash having children
    def check_outward_nodes(call_graph, source)
      call_graph.key?(source) && call_graph[source].size > 0
    end

    # check if there exists nodes that are going to the destination or not
    # method checks if the dest node is present in any of the values in the call hash
    def check_inward_node(call_graph, dest)
      call_graph.each do |_, v|
        return true if v.keys.include? dest
      end
    end

    # check fi the trace_path hash is given in the object
    # check if given then its empty or not
    def trace_path_pref_given?(preferences)
      if preferences.trace_path.nil?
        return false
      else
        return false if preferences.trace_path.empty?
      end

      true
    end

  end
end
