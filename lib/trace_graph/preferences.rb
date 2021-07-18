# frozen_string_literal: true

class TraceGraph::Preferences
  PREFERENCES = %w[color name shape edge_color edge_label nodes]
  TRACE_PREFERENCES = %w[depth time_unit path output_file file_type callers callees]
  UNITS = %w[ms s min]

  def initialize
    yield self if block_given?
  end

  def self.preferences(args, pref_type)
    args.each do |pref|
      if pref_type == 'method'
        attr_accessor "method_#{pref}"
      else
        attr_accessor "trace_#{pref}"
      end
    end
  end

  def self.symbolize_method_names(string_array)
    # string_array.map { |method| method.to_sym }
    string_array.map(&:to_sym)
  end

  preferences symbolize_method_names(PREFERENCES), 'method'
  preferences symbolize_method_names(TRACE_PREFERENCES), 'trace'

  def set_time(unit, elapsed_time)
    case unit
    when 'ms'
      elapsed_time
    when 's'
      elapsed_time.divmod(1000)
    when 'm'
      elapsed_time.divmod(1000 * 60)
    else
      elapsed_time # default it wil be milliseconds
    end
  end
end
