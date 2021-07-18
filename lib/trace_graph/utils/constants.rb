# frozen_string_literal: true

module TraceGraph
  module Constants
    # edge color constants
    DEFAULT_EDGE_COLOR = 'green3'

    # node color constants
    DEFAULT_NODE_COLOR = 'green'
    NODE_PERF_HIGH = 'red'
    NODE_PERF_MEDIUM = 'orange'
    NODE_PERF_LOW = 'low'

    # error message constants
    TRACE_PATH_ERROR_MSG = 'Source or destination provided doesnt have incoming or outgoing nodes for tracing path, check the graph'
    TRACE_PATH_WARNING_MSG = 'Graph will not have any paths highlighted if invalid source or dest is given but graph will still be printed'
    MULTIPLE_METHOD_ERROR_MSG = 'One of the methods given does not exist, please check again'
    NO_VALUE_PROVIDED_ERROR_MSG = 'No value provided for'
    TRACE_NODE_PATH_ERROR_MSG = 'Graph will not have any paths highlighted due to given node not having incoming or outgoing nodes'
    TRACE_NODE_PATH_WARNING_MSG = 'Graph will not have any paths highlighted if given node doesnt have incoming or outgoing nodes,
                                    but graph will still be printed'
    # error color constants
    ERROR_COLOR = 'red'
    WARNING_COLOR = 'yellow'
    INFO_COLOR = 'blue'
    SUCCESS_COLOR = 'green'

    # file name constant
    DEFAULT_FILE_NAME = 'trace_graph'

    # Trace constants
    TRACE_INCOMING_NODES = 'incoming'
    TRACE_OUTGOING_NODES = 'outgoing'
  end
end
