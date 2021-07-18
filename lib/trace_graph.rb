require 'trace_graph/helpers/profiler_helpers'
require 'trace_graph/utils/utils'
require 'trace_graph/helpers/graph_helpers'
require 'trace_graph/utils/constants'
require 'trace_graph/validators'
require 'core_extensions/string/colorizer'
require 'trace_graph/base_graph'
require 'trace_graph/version'
require 'trace_graph/call_stack'
require 'trace_graph/finder'
require 'trace_graph/method_call_info'
require 'trace_graph/tracer'
require 'trace_graph/preferences'
require 'trace_graph/grapher_exception'

module TraceGraph
  class Error < StandardError; end
  # Your code goes here...

  def self.trace_doc(result)
    require 'tempfile'
    f = Tempfile.open('dot')
    puts result
    f.write result
    f.close
    system("dot -Tpdf #{f.path} -o call_graph_test_color.pdf")
  end

  # def self.init_trace( preferences: nil, &block)
  #   @tracer = Tracer.new(CallStack.new(prefs: preferences))
  #   @tracer.enable
  #   yield
  #   @tracer.disable
  #   trace_doc @tracer.result
  # end

end
