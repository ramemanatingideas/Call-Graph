module TraceGraph
  class CallStack
    attr_accessor :methods, :calls, :call_stack

    include GraphHelpers
    include Validators
    include Utils

    def initialize(**init_params)
      @call_stack = []
      @calls = {}
      @methods = {}
      @graph_prefs = []
      @param_passed = init_params[:prefs] unless init_params[:prefs].nil?
      # @colour_nodes = if @param_passed.nil?
      #                   false
      #                 else
      #                   init_params[:prefs].method_nodes.nil? ? false : true
      #                 end

      # This below line does what the above line does , it does the same with a generic method
      @colour_nodes = check_method_and_set(init_params[:prefs],'method_nodes', false, true)

      @trace_path = check_method_and_set(init_params[:prefs], 'trace_path', false, true)

      @trace_outgoing = check_method_and_set(init_params[:prefs], 'trace_callees', false, true)

      @trace_incoming = check_method_and_set(init_params[:prefs], 'trace_callers', false, true)

    end

    def record_method_call(event, method_name, class_name = nil, time)
      case event
      when :call
        @call_stack << MethodCallInfo.new(method_name.to_s, 0, call_time: time, total_time: 0, self_time: 0)
      when :return
        return if @call_stack.empty?

        method = @call_stack.pop

        method.call_time = time - method.call_time

        add_method_to_call_tree method
      end
    end

    def add_method_to_call_tree(method)
      @methods[method.method_name] ||= method.clone
      @methods[method.method_name].total_time += method.call_time
      @methods[method.method_name].self_time += method.call_time
      @methods[method.method_name].method_call_count += 1
      method.method_call_count += 1

      if parent = @call_stack.last
        # print "parent ", parent.inspect, "method ", method.inspect
        @calls[parent.method_name] ||= {}
        @calls[parent.method_name][method.method_name] ||= 0
        @calls[parent.method_name][method.method_name] += 1

        # calculating self time
        parent_method_obj = method.clone
        parent_method_obj.method_call_count = 0
        parent_method_obj.self_time = 0
        parent_method_obj.total_time = 0
        @methods[parent.method_name] ||= parent_method_obj
        @methods[parent.method_name].self_time -= method.call_time
      end
    end

    def show_stack
      p @call_stack
    end

    # This method returns the final dot string based on the param and options passed
    # Only one option is considered and not multiple on the same
    # Follows a precedence to return the dot string
    # Precedence order : no_prefs > trace_path_pref > trace_node_pref (incoming if given) > trace_node_pref(outgoing if given)
    # if both given (incoming and outgoing) then it takes outgoing as the preference
    def result
      return dot_notation if @param_passed.nil?

      return trace_path if @trace_path

      return trace_node_call_path(TraceGraph::Constants::TRACE_INCOMING_NODES) if @trace_incoming

      trace_node_call_path(TraceGraph::Constants::TRACE_OUTGOING_NODES) if @trace_outgoing
    end

    private

    # checks the preferences given , evaluates for validity and raises exception if not valid
    # Method is for trace_node (incoming and outgoing path for a given node)
    def trace_node_calls_preferences(pref_block)
      # remove the color option if it exists and check for the nodes
      trace_method = if @trace_incoming
                       pref_block.trace_callers.slice(:method)
                     elsif @trace_outgoing
                       pref_block.trace_callees.slice(:method)
                     end

      if !check_nodes_exist(trace_method)
        raise GrapherException.new "The specified method #{pref_block.method_name} doesnt exist", 'check_node_exists'
      else
        # Check for orphan node , which doesnt have outgoing or incoming nodes, if orphan raise Error
        unless check_outward_nodes(@calls, trace_method[:method]) || check_inward_node(@calls, trace_method[:method])
          raise GrapherException.new "#{TraceGraph::Constants::TRACE_PATH_ERROR_MSG}, check again",
                                     'trace_node_calls_preferences'
        end
      end

    end

    # Method is for node colouring, checks if the methods are valid
    def node_color_preferences(pref_block)
      # testing out the object based value setting
      if pref_block.method_nodes.nil?
        if check_nodes_exist pref_block.method_name
          @graph_prefs = "#{pref_block.method_name} [style=filled, fillcolor=#{pref_block.method_color}]"
        else
          raise GrapherException.new "The specified method #{pref_block.method_name} doesnt exist", 'check_node_exists'
        end
      else
        if check_nodes_exist pref_block.method_nodes, true
          pref_block.method_nodes.each { |node_name, node_color|
            @graph_prefs << "#{node_name} [style=filled, fillcolor=#{node_color}]"
          }
        else
          raise GrapherException.new TraceGraph::Constants::MULTIPLE_METHOD_ERROR_MSG, 'check_node_exists'
        end

        @graph_prefs.join("\n")
      end
    end

    # Method is for trace path validation, checks if the source and dest are valid nodes, if not raise exception
    def trace_path_preferences(pref_block)
      if !trace_path_pref_given? pref_block
        raise GrapherException.new "#{TraceGraph::Constants::NO_VALUE_PROVIDED_ERROR_MSG} trace_path, check again",
                                   'trace_path_preferences'
      else
        # remove the color option if it exists and check for the nodes
        trace_path_methods = (
          if pref_block.trace_path.key?(:color)
            pref_block.trace_path.slice(:source, :dest)
          else
            pref_block.trace_path
          end
        )
        # check if the methods passed are valid or not
        unless check_nodes_exist(trace_path_methods)
          raise GrapherException.new TraceGraph::Constants::MULTIPLE_METHOD_ERROR_MSG, 'check_node_exists'
        end
      end
    end

    def dot_notation
      dot = %(
            digraph G {
              #{graph_nodes}
              #{graph_links}
              #{node_color_preferences(@param_passed) if @colour_nodes}
            }
          )
    end

    def graph_nodes
      nodes = ''
      @methods.each do |name, method_info|
        nodes << "#{name.dump} [label=\"#{name}\\ncalls: #{method_info.method_call_count}\\ntotal time: #{method_info.total_time}\\nself time: #{method_info.self_time}\"];\n"
      end
      nodes
    end

    def graph_links
      links = ''
      @calls.each do |parent, children|
        children.each do |child, count|
          links << "#{parent.dump} -> #{child.dump} [label=\"#{count}\"];\n"
        end
      end
      links
    end

    def trace_path
      trace_path_preferences @param_passed

      source = @param_passed.trace_path[:source]
      dest = @param_passed.trace_path[:dest]
      color = @param_passed.trace_path[:color] if @param_passed.trace_path.key?(:color)

      # validate if source and dest have outward and inward nodes respectively
      # make the path with the given source and destination if valid
      unless validate_trace_path @calls, source, dest
        # puts 'Source or destination doesnt have incoming or outgoing nodes, check the graph'.red
        puts colorize_output TraceGraph::Constants::TRACE_PATH_ERROR_MSG, TraceGraph::Constants::ERROR_COLOR
        puts colorize_output TraceGraph::Constants::TRACE_PATH_WARNING_MSG, TraceGraph::Constants::WARNING_COLOR
      end

      make_path source, dest, color
    end

    def trace_node_call_path(direction)
      trace_node_calls_preferences @param_passed

      node = if direction == 'incoming'
               @param_passed.trace_callers[:method]
             else
               @param_passed.trace_callees[:method]
             end
      color = if direction == 'incoming'
               @param_passed.trace_callers[:color]
             else
               @param_passed.trace_callees[:color]
              end
      # make path for the node based on the direction
      make_node_path(node, color, direction)
    end

    # This method is called for tracing all possible paths from Source to Destination
    # Replaces the dot string with the new ones (changed by adding path highlighting)
    # @param [String] source
    # @param [String] dest
    # @param [String] color
    # @return [String]
    def make_path(source, dest, color)
      # check if the param is nil, if yes then set to default color constant
      # else set the param value
      edge_color = color.nil? ? TraceGraph::Constants::DEFAULT_EDGE_COLOR : color
      graph_obj = TraceGraph::BaseGraph::Graph.new
      graph_obj.convert_call_to_graph @calls
      paths = graph_obj.bfs_get_path_hash source, dest
      replacements = convert_paths_to_dot source, paths, edge_color
      puts colorize_output TraceGraph::Constants::TRACE_NODE_PATH_ERROR_MSG, TraceGraph::Constants::ERROR_COLOR
      puts colorize_output TraceGraph::Constants::TRACE_NODE_PATH_WARNING_MSG, TraceGraph::Constants::WARNING_COLOR

      modify_dot dot_notation, replacements
    end

    # This method is called for tracing the outgoing or incoming nodes for a node
    # Outgoing or incoming is based on the direction passed as param
    # Replaces the dot string with the new ones (changed by adding path highlighting)
    # @param [String] node
    # @param [String] color
    # @param [String] direction
    # @return [String]
    def make_node_path(node, color, direction)
      edge_color = color.nil? ? TraceGraph::Constants::DEFAULT_EDGE_COLOR : color

      graph_obj = TraceGraph::BaseGraph::Graph.new
      graph_obj.convert_call_to_graph @calls

      if direction == 'incoming'
        replacements = convert_callers_to_dot(node, graph_obj.graph, edge_color)
      else
        callee_nodes = graph_obj.graph[node]
        replacements = convert_callee_to_dot(node, callee_nodes, edge_color)
      end

      modify_dot dot_notation, replacements
    end

    # This methods checks if the nodes passed as param is present in the methods recorded
    # Input are Hash (with key as method names and another without) and String for single method checks
    # Returns boolean if exists true else false
    def check_nodes_exist(nodes, method_name_as_key = false)
      # This condition exists to check if the given hash has to be checked with the key as names
      # eg: for method_nodes coloring input is in the format {'method1': 'blue', 'method2': 'green'}
      # This case would require to take out the key itself as method name and hence the method_name_as_key
      if nodes.is_a?(Hash) && method_name_as_key
        node_names = get_all_keys_as_string nodes
        (@methods.keys & node_names).size == node_names.size
      elsif nodes.is_a?(Hash)
        node_names = get_all_keys_as_string nodes, false
        (node_names - @methods.keys).empty?
      end
    end

    def get_all_keys_as_string(hash, name_in_key = true)
      # check if the key itself has the name
      # else take its values
      if name_in_key
        hash.keys.map(&:to_s)
      else
        hash.values.map(&:to_s)
      end
    end

    def filter_inbuilt_methods?(class_name, method_name)
      user_defined_methods = class_name.instance_methods(false)
      user_defined_methods.include?(method_name)
    end

    def make_path_if_valid(source, dest, color)
      if validate_trace_path @calls, source, dest
        make_path source, dest, color
      else
        raise GrapherException.new 'Source or destination doesnt have incoming or outgoing nodes, check the graph',
                                   'validate_trace_path'
      end
    end

  end
end
