require 'forwardable'

module Esse
  # The idea here is to add useful methods to the ruby standard objects without
  # monkey patching them
  module HashUtils
    module_function

    def deep_dup(hash)
      hash.each_with_object({}) do |(key, value), result|
        result[key] = \
          if value.is_a?(Hash)
            deep_dup(value)
          else
            value
          end
      end
    end

    def deep_transform_keys(hash, &block)
      hash.each_with_object({}) do |(key, value), result|
        result[yield(key)] = \
          if value.is_a?(Hash)
            deep_transform_keys(value, &block)
          else
            value
          end
      end
    end

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

    def explode_keys(hash, separator = '.')
      hash.each_with_object({}) do |(key, value), result|
        is_symbol = key.is_a?(Symbol)
        keys = key.to_s.split(separator)
        last_key = keys.pop
        current = keys.reduce(result) { |memo, k| memo[is_symbol ? k.to_sym : k] ||= {} }
        current[is_symbol ? last_key.to_sym : last_key] = value
      end
    end
  end
end
