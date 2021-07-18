module TraceGraph
  module Utils
    # colourise the output
    def colorize_output(msg, color)
      msg.send(color.to_sym)
    end

    def generate_file(file_object, file_name, file_type)
      system("dot -T#{file_type} #{file_object.path} -o #{file_name}.#{file_type}")
    end

    # This generic method basically does the following
    # output_file_pref = if preferences.nil?
    #                      nil
    #                    else
    #                      preferences.trace_output_file.nil? ? nil : preferences.trace_output_file
    #                    end
    # it is used to check if null and then set the value based on the condition
    # @param object [[Object]] the object of the class that is needed to be checked
    # @param method [[string]] the method of the instance that needs to be checked
    # @param default_return_val [[Object]] the default return value that needs to be returned on nil
    # @param custom_return_value (optional) [[Object]] the custom value to be returned, if not given it will take the object itself
    # @return [[Object]] this depends on the return specified
    def check_method_and_set(object, method, default_return_val, custom_return_value=nil)
      if object.nil?
        default_return_val
      else
        if custom_return_value.nil?
          object.send(method.to_sym).nil? ? default_return_val : object.send(method.to_sym)
        else
          object.send(method.to_sym).nil? ? default_return_val : custom_return_value
        end
      end
    end

    def check_object_hash_given?(object, method)
      if object.send(method.to_sym).nil?
        return false
      else
        return false if object.send(method.to_sym).empty?
      end

      true
    end

    def get_object_hash_value(object, method, key)
      if check_object_hash_given?(object, method)
        object.send(method.to_sym).send(:[], key.to_sym)
      end
    end

  end
end