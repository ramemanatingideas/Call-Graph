module TraceGraph
  class GrapherException < StandardError
    attr_reader :error_cause
    def initialize(message="Something went wrong with Grapher", cause)
      @error_cause = cause
      super(message)
    end
  end
end