module TraceGraph
  class Tracer
    include ProfilerHelpers
    # This constructor initiates the Tracepoint API
    # @param [Object] reporter (CallStack)
    # @param [Object] clock_type (default cpu)
    def initialize(reporter, clock_type: :cpu)
      # Initialise the instance variable with param passed
      @reporter = reporter

      # Tracepoint to trace only method event call and return
      @tracepoints = %i[call return].collect do |event|
        TracePoint.new(event) do |trace|
          time = clock_type == :wall ? wall_time : cpu_time
          # record_method call for the given event and method)
          reporter.record_method_call(event, trace.method_id, trace.defined_class, time)
        end
      end
    end

    # Enables the tracer to start recording
    def enable
      @tracepoints.each(&:enable)
    end

    # Disables the tracer to stop recording
    def disable
      @tracepoints.each(&:disable)
    end

    # return the result of the recordings or tracings
    # @return [String](CallStack result method return)
    def result
      @reporter.result
    end
  end
end
 
