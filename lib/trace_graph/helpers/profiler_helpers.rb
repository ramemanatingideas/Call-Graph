module TraceGraph
  module ProfilerHelpers
    def cpu_time
      Process.clock_gettime Process::CLOCK_PROCESS_CPUTIME_ID, :microsecond
    end

    def wall_time
      Process.clock_gettime Process::CLOCK_MONOTONIC, :microsecond
    end
  end
end

