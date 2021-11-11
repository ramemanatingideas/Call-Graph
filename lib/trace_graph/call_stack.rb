module TraceGraph
  # This class is responsible for creating the graph
  # By default if no preferences given it will create a basic graph
  # If preferences given it will generate the result based on it.
  class CallStack
    attr_accessor :methods, :calls, :call_stack

    include GraphHelpers
    include Validators
    include Utils

    def initialize(**init_params)
      # instance variables to hold call_graph, methods, stack
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

      @trace_path = chec_method_and_set(init_params[:prefs], 'trace_path', false, true)

      @trace_outgoing = check_method_and_set(init_params[:prefs], 'trace_callees', false, true)

      @trace_incoming = check_method_and_set(init_params[:prefs], 'trace_callers', false, true)

      @trace_depth = check_method_and_set(init_params[:prefs], 'trace_depth', false, true)

      @max_depth = init_params[:prefs].trace_depth if @trace_depth

    end

    # Record method call does the following
    # If event traced is a call action then push into stack (call_stack instance variable)
    # If return pop out of stack and add method to call_graph.
    def record_method_call(event, method_name, class_name = nil, time)
      case event
      when :call

        current_depth = 0
        if @call_stack.empty?
          @call_stack << MethodCallInfo.new(method_name.to_s, 0, call_time: time, total_time: 0, self_time: 0, depth: current_depth)
        else
          # when stack is not empty get the parent's depth
          # add parent's depth to the current node
          parent_depth = @call_stack.last.depth
          current_depth = parent_depth + 1
          @call_stack << MethodCallInfo.new(method_name.to_s, 0, call_time: time, total_time: 0, self_time: 0, depth: current_depth)
        end

      when :return
        return if @call_stack.empty?

        method = @call_stack.pop

        # check if trace_depth pref is given else continue with normal cases
        if @trace_depth
          # if trace depth is enabled we do depth filter
          if method.depth <= @max_depth
            method.call_time = time - method.call_time
            add_method_to_call_tree method
          end
        else
          # If trace_depth is not enabled then we do trace for all depth
          method.call_time = time - method.call_time
          add_method_to_call_tree method
        end

      end
    end

    # Method calculates the calls made, time taken (self and total)
    def add_method_to_call_tree(method)
      @methods[method.method_name] ||= method.clone
      @methods[method.method_name].total_time += method.call_time
      @methods[method.method_name].self_time += method.call_time
      @methods[method.method_name].method_call_count += 1
      method.method_call_count += 1

      if parent = @call_stack.last
        # print "parent ", parent.inspect, "method ", method.inspect, "\n"
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



    # This method returns the final dot string based on the param and options passed
    # Only one option is considered and not multiple on the same
    # Follows a precedence to return the dot string
    # Precedence order : no_prefs > trace_path_pref > trace_node_pref (incoming if given) > trace_node_pref(outgoing if given)
    # if both given (incoming and outgoing) then it takes outgoing as the preference
    def result

      return trace_path if @trace_path

      return trace_node_call_path(TraceGraph::Constants::TRACE_INCOMING_NODES) if @trace_incoming

      return trace_node_call_path(TraceGraph::Constants::TRACE_OUTGOING_NODES) if @trace_outgoing

      # this will default return if no preferences given
      dot_notation
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
      # checks if the methods named provided are valid and existing
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
    # @param [Hash] pref_block
    # @return [Boolean]
    def node_color_preferences(pref_block)
      # checks if the preferences given is method_nodes or method_node (singular)
      # If singular check for valid and existing nodes for 1 node
      # If not check for list of nodes given
      # Refer Preferences class to know about the type of attribute
      if pref_block.method_nodes.nil?
        if check_nodes_exist pref_block.method_name
          @graph_prefs = "#{pref_block.method_name} [style=filled, fillcolor=#{pref_block.method_color}]"
        else
          raise GrapherException.new "The specified method #{pref_block.method_name} doesnt exist", 'check_node_exists'
        end
      else
        # Check for valid methods for a list given. If valid then add item to array of strings
        if check_nodes_exist pref_block.method_nodes, true
          pref_block.method_nodes.each { |node_name, node_color|
            @graph_prefs << "#{node_name} [style=filled, fillcolor=#{node_color}]"
          }
        else
          raise GrapherException.new TraceGraph::Constants::MULTIPLE_METHOD_ERROR_MSG, 'check_node_exists'
        end
        # adds a new line at the end of each item in the array
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
        # Checks can be performed only on the method names hence not considering color
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

    # Final Dot string
    # @return [String]
    def dot_notation
      # returns the final dot string, checks if color_nodes preference is given and makes addition.
      dot = %(
            digraph G {
              #{graph_nodes}
              #{graph_links}
              #{node_color_preferences(@param_passed) if @colour_nodes}
            }
          )
    end

    # Graph nodes method will create nodes for the given method names (@methods)
    # @return [String]
    def graph_nodes
      nodes = ''
      @methods.each do |name, method_info|
        nodes << "#{name.dump} [label=\"#{name}\\ncalls: #{method_info.method_call_count}\\ntotal time: #{method_info.total_time}\\nself time: #{method_info.self_time}\"];\n"
      end
      nodes
    end

    # Adds graph link string to the methods based on the call graph defined in @calls
    # @return [String]
    def graph_links
      links = ''
      @calls.each do |parent, children|
        children.each do |child, count|
          links << "#{parent.dump} -> #{child.dump} [label=\"#{count}\"];\n"
        end
      end
      links
    end

    # This method checks for the validity of methods and initiates tracing
    # It wont halt the tracing and will continue with no coloration of the edges or path
    # Console error message will be flashed but execution will continue
    # Returns string of the path
    # @returns [String]
    def trace_path
      # Validation of the method nodes is performed (This will halt the execution)
      # checks if the methods given as source and destination are valid
      trace_path_preferences @param_passed

      source = @param_passed.trace_path[:source]
      dest = @param_passed.trace_path[:dest]
      color = @param_passed.trace_path[:color] if @param_passed.trace_path.key?(:color)

      # validate if source and dest have outward and inward nodes respectively
      # make the path with the given source and destination if valid
      # This will not halt the execution and only output to console and continue
      unless validate_trace_path @calls, source, dest
        # puts 'Source or destination doesnt have incoming or outgoing nodes, check the graph'.red
        puts colorize_output TraceGraph::Constants::TRACE_PATH_ERROR_MSG, TraceGraph::Constants::ERROR_COLOR
        puts colorize_output TraceGraph::Constants::TRACE_PATH_WARNING_MSG, TraceGraph::Constants::WARNING_COLOR
      end

      # calls method to perform the path highlighting
      make_path source, dest, color
    end

    # method is common for executing caller and callee paths
    # Sets the return based on direction as param
    # @param [String]
    # @returns [String]
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
      # Creates graph object to perform graph operations
      graph_obj = TraceGraph::BaseGraph::Graph.new
      # Convert call_graph object (Hash of Hash) to Graph object representation(Adjacency List)
      graph_obj.convert_call_to_graph @calls
      # Perform BFS on the call_graph (converted to adj list) returns [Array[Array]]
      paths = graph_obj.bfs_get_path_hash source, dest
      # Converts the path (Array of Array contains all possible paths each path as element) to DOT stirng
      replacements = convert_paths_to_dot source, paths, edge_color
      puts colorize_output TraceGraph::Constants::TRACE_NODE_PATH_ERROR_MSG, TraceGraph::Constants::ERROR_COLOR
      puts colorize_output TraceGraph::Constants::TRACE_NODE_PATH_WARNING_MSG, TraceGraph::Constants::WARNING_COLOR
      # replace the current dot string with the new graph link string as updated dot
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

    # The below implementation is for validation of the method names passed in preferences
    # for different actions (trace_path, color_nodes) etc .
    # check_nodes_exist is the parent method which performs the validation.
    # Below methods after that are helpers to this method and can be ignored

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

    # This method is currently Unused and is STALE
    # Can be ignored
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


