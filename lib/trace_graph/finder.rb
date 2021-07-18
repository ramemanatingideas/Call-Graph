require 'fileutils'

module TraceGraph
  module Finder
    extend Utils
    def self.start_tracing
      @tracer = Tracer.new(CallStack.new)
      @tracer.enable
    end

    def self.stop_tracing
      @tracer.disable
      @tracer.result
    end

    def self.trace_doc(result, file_name = nil, file_type = 'pdf')
      result_file_name = file_name.nil? ? TraceGraph::Constants::DEFAULT_FILE_NAME : file_name
      puts colorize_output "Writing to file #{result_file_name}.pdf", TraceGraph::Constants::INFO_COLOR
      require 'tempfile'
      f = Tempfile.open('dot')
      puts colorize_output result, TraceGraph::Constants::SUCCESS_COLOR
      f.write result
      f.close
      generate_file f, result_file_name, file_type
      # system("dot -Tpdf #{f.path} -o #{result_file_name}.pdf")
    end

    def self.init_trace(preferences: nil, clock_type: :cpu, &block)
      @tracer = Tracer.new(CallStack.new(prefs: preferences), clock_type: clock_type)
      @tracer.enable
      block.call
      @tracer.disable
      # output_file_pref = if preferences.nil?
      #                      nil
      #                    else
      #                      preferences.trace_output_file.nil? ? nil : preferences.trace_output_file
      #                    end
      # method does the above part using a generic method
      output_file_name = check_method_and_set(preferences, 'trace_output_file', nil)
      output_file_type = check_method_and_set(preferences, 'trace_file_type', 'pdf')
      trace_doc @tracer.result, output_file_name, output_file_type
    end

  end
end
