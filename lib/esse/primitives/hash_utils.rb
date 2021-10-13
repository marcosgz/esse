require 'forwardable'

module Esse
  # The idea here is to add useful methods to the ruby standard objects without
  # monkey patching them
  module HashUtils
    module_function

    def deep_merge(target, source)
      target.merge(source) do |key, oldval, newval|
        if oldval.is_a?(Hash) && newval.is_a?(Hash)
          deep_merge(oldval, newval)
        else
          newval
        end
      end
    end

    def deep_merge!(target, source)
      target.merge!(source) do |key, oldval, newval|
        if oldval.is_a?(Hash) && newval.is_a?(Hash)
          deep_merge!(oldval, newval)
        else
          newval
        end
      end
    end
  end
end
