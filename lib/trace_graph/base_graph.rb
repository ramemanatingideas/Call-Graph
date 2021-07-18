module TraceGraph
  module BaseGraph
    class Graph
      attr_reader :graph

      def initialize
        @graph = Hash.new { |h, k| h[k] = [] }
        @visited = []
      end

      def add_edge(a, b)
        @graph[a].push(b)
      end

      def print_graph
        p @graph
      end

      def print_edges(vertex)
        p @graph[vertex]
      end

      def bfs_traverse_graph(vertex_node)
        queue = []
        visited_hash = { vertex_node => true }
        # @visited << vertex_node
        queue.push(vertex_node)

        until queue.empty?
          current = queue.shift
          print current, "\n"

          @graph[current].each do |node|
            print 'child node:', node, "\n"
            # next if @visited.include?(node)
            next if visited_hash[node]

            queue.push(node)
            visited_hash[node] = true
          end

        end
      end

      def visited_node?(node, path)
        if node.is_a?(Hash)
          path.include?(node[:method])
        else
          path.include?(node)
        end
      end

      def print_path(path)
        pp path
      end

      # Method takes in src and dest nodes and makes up queue with only node name in hash except the source
      # and with call_hash ie [["main",{:method=>"something", :call=>3},{:method=>"something_else", :call=>4}]
      # for (source="main", dest="something_else")
      # @param  [String] source
      # @param [String] dest
      # @return all paths found [Array[Array]]
      def bfs_get_path_hash(source, dest)
        all_paths = []
        queue = []
        path = []
        path << source
        queue << path
        # puts queue
        until queue.flatten.empty?
          path = queue.shift
          latest = path[-1]

          latest_node = latest.is_a?(Hash) ? latest[:method] : latest
          # print_path path if latest_node == dest

          # if the src is the dest then the path is complete
          # add the path to the result
          all_paths << path if latest_node == dest

          # format the path array for checking visited
          formatted_path = format_path(path)
          @graph[latest_node].each do |node|
            next if visited_node? node, formatted_path

            new_path = path.map(&:itself)
            new_path.push(node)
            # push the new path to the queue
            queue.push new_path
          end
        end
        all_paths
      end

      # This method does not have any return values as it sets the value to the object attr @graph
      # @param [Hash] call_hash
      def convert_call_to_graph(call_hash)
        # format the call_hash to have only key with value as array and not a hash
        formatted_hash = {}
        # Approach TWO
        # make the hash in this form having the count as a hash in it
        # ie "something"=>
        #   [{:method=>"something_else", :count=>12},
        #    {:method=>"check_symbolic_functions?", :count=>12}]

        call_hash.each do |key, value|
          formatted_hash[key] = []
          value.each do |val|
            temp_hash = { method: val.first, count: val.last }
            formatted_hash[key].push(temp_hash)
          end
        end

        # This method sets the @graph instance variable with the values
        formatted_hash.each do |caller, callee|
          # print 'caller', caller, 'callee', callee, "\n"
          callee.each { |method| add_edge caller, method }
        end

      end

      # This method takes in a node name and returns the callers of the node
      # and the caller node itself with its hash (ie calls made from the caller)
      # @param [String] node_name
      # @return [[Array(String)], [Array(Hash)]]
      # the self. part is just a hack to get this method called in graph_helpers module, ik its bad
      def self.get_callers(call_hash, node_name)
        callers = []
        caller = []
        call_hash.each do |k, v|
          v.each do |i|
            if i[:method] == node_name
              callers << k
              caller << i
            end
          end
        end
        [callers, caller]
      end

      def get_callees(node_name)
        @graph[node_name]
      end

      private

      # this method is a kind of a hack to make array of type
      # ["main", {method: 'hello', call: 10}, {method: 'world', call: 10}] => ["main", "hello", "world"]
      # There is a guarantee that the first element in the array is a string (ie the source) and not hash
      def format_path(path)
        return path if path.empty? || path.nil? || path.size == 1

        # remove the first element which is of string type
        source = path.shift
        # convert the hash elements to strign
        formatted_path = path.map{ |x| x[:method] }
        # add the removed first element to the front
        # do this to both formatted_path and path
        formatted_path.unshift source
        path.unshift source
        formatted_path
      end
    end
  end
end