module TraceGraph
  class Tracer
    include ProfilerHelpers
    def initialize(reporter, clock_type: :cpu)
      @reporter = reporter
      @tracepoints = %i[call return].collect do |event|
        TracePoint.new(event) do |trace|
          time = clock_type == :wall ? wall_time : cpu_time
          reporter.record_method_call(event, trace.method_id, trace.defined_class, time)
        end
      end
    end

    def enable
      @tracepoints.each(&:enable)
    end

    def disable
      @tracepoints.each(&:disable)
    end

    def result
      @reporter.result
    end

  end
end
