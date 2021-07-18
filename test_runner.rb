$:<< File.join(File.dirname(__FILE__), "../lib")
require 'trace_graph'

class Trial
  def sample_setter=(value)
    "somevalue is returned"
    Sample.a
  end

  def test_main
    10.times { |_i| test_more }
    20
  end

  def test_more
    'something else'
  end

  def main
    3.times do
      find_many_square_roots
      find_many_squares
    end

    5.times do
      something
    end

    p recursive_adder [1, 2, 3], 0, 3
  end

  def find_many_square_roots
    5000.times { |i| Math.sqrt(i) }
    something
  end

  def find_many_squares
    5000.times { |i| i ** 2 }
    something
    something_else
  end

  def something
    a = 100
    'hello world'
    something_else
    check_symbolic_functions? "sample"
  end

  def something_else
    'whatever'
    check_symbolic_functions? "something"
  end

  def recursive_adder(array, index, end_index)
    if index >= end_index
      something
      something_else
      0
    else
      array[index] + recursive_adder(array, index + 1, end_index)
    end
  end

  def check_symbolic_functions?(value)
    return false if value == "sample"
    return true if value == "something"
  end

end

# Grapher::Finder.start_tracing
#   t = Trial.new
#   t.main
#   # t.sample_setter=4
#   result = Grapher::Finder.stop_tracing
#   Grapher::Finder.trace_doc result


# passing proc approach 1

# prefs = Proc.new do |name, colour|
#   instance_variable_set("@name", name)
#   instance_variable_set("@colour", colour)
# end


# passing an object itself

# prefs =

# prefs = Grapher::Preferences.new.tap do |pref|
#   pref.name = 'something'
#   pref.color = 'green'
# end
#
# puts prefs

prefs2 = TraceGraph::Preferences.new
prefs2.method_color = 'red'
prefs2.method_name = 'find_many_square_root'
prefs2.method_nodes = {'something': 'red', 'something_else': 'green', 'recursive_adder': 'pink'}
prefs2.depth = 2

TraceGraph.init_trace(preferences: prefs2) do
  t = Trial.new
  t.main
  t.test_main.to_s
end