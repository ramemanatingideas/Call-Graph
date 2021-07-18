module TraceGraph
  class MethodCallInfo
    attr_accessor :method_name, :method_call_count, :class_name, :self_time, :total_time, :call_time, :count

    def initialize(method_name, count, class_name = nil, call_time: nil ,total_time: nil, self_time: nil)
      @method_name = method_name
      @method_call_count = count
      @class_name = class_name
      @total_time = total_time
      @self_time = self_time
      @call_time = call_time
    end
  end
end