module TraceGraph
  module GraphHelpers
    # Makes dot string to create edge
    # @param [String] src
    # @param [String] dest
    # @param [String] label_count
    # @param [String] label_count
    # @return [String]
    def make_dot_edge(src, dest, label_count, label_color)
      # Eg: "\"main\" -> \"recursive_adder\" [label=\" 1\"]";
      "\"#{src}\" -> \"#{dest}\" [label=\"#{label_count}\", color=\"#{label_color}\"]\n"
    end

    def split_dot_string(dot_string)
      # split the string on newline and return an array of strings
      dot_string.split("\n")
    end

    # String replace Main dot string with the new strings.
    # This method only modifies the lines in the string and
    # not replace the whole string
    def modify_dot(main_dot_string, replacement_strings)
      # get replacement strings
      split_string_replacements = replacement_strings.split("\n")

      # get pattern strings to match and replace
      split_string_patterns = []
      split_string_replacements.each { |i| splt_string_patterns << i.split(',').first + ']' }

      # replace the string at its occurrence by taking the pattern
      split_string_replacements.each_with_index do |replacement, i|
        # this line is valid only when all paths are set to 1 colour
        # this line checks if the modification is already made
        # as searching for the pattern will not yield anything as it is already replaced
        next if main_dot_string[replacement]

        main_dot_string[split_string_patterns[i]] = replacement
      end
      # return the modified dot
      main_dot_string
    end

    # Below methods replace_dot_string and sub_dot_string 
    # are not being used and exists for future uses.Can be
    # ignored for now

    # this method directly replaces the pattern with the new string
    # This can raise IndexError
    def replace_dot_string(dot_string, pattern, replacement)
      dot_string[pattern] = replacement
    end

    # method uses sub to replace the string
    def sub_dot_string(dot_string, pattern, replacement)
      dot_string.sub(pattern, replacement)
    end

    # @param [String] src - source
    # @param [Array[Array]] paths
    # @param [String] color
    # @return [String]
    def convert_paths_to_dot(src, paths, color)
      dot_string = ''
      paths.each do |path|
        # Refer to the structure of paths object.
        # First element will be a single string item
        # Rest of the items will be array of array
        # This enum was used to iterate and get the next item without causing null reference error.
        # It is due to the structure.
        path.each_cons(2) do |node, next_node|
          dot_string += if src == node
                          # dot_string += src + " -> " + next_node[:method] + "\n"
                          make_dot_edge(src, next_node[:method], next_node[:count], color)
                        else
                          # dot_string += node[:method] + " -> " + next_node[:method] + "\n"
                          make_dot_edge(node[:method], next_node[:method], next_node[:count], color)
                        end
        end
      end
      dot_string
    end

    # @param [String] src
    # @param [Hash] callees
    # @param [String] color
    # @return [String] dot_string
    # This method makes dot string by connecting the source node to its children (callees)
    def convert_callee_to_dot(src, callees, color)
      dot_string = ''

      callees.each do |node|
        dot_string += make_dot_edge(src, node[:method], node[:count], color)
      end

      dot_string
    end

    # @param [String] node_name
    # @param [Hash] call_hash
    # @return [String] color
    # This method returns dot string by connecting the parent (callers) to the specified nodes
    # The method gets all the callers for the node (ie the nodes which calls this node) and connects to the node
    def convert_callers_to_dot(node_name, call_hash, color)
      callers, caller = TraceGraph::BaseGraph::Graph.get_callers(call_hash, node_name)
      dot_string = ''
      # size of both callers and callees are same
      callers.each_with_index do |calling_method, i|
        dot_string += make_dot_edge(calling_method, caller[i][:method], caller[i][:count], color)
      end

      dot_string
    end

  end
end

