# frozen_string_literal: true

module Esse
  class DynamicTemplate
    # @param [Array, Hash] value The list of dynamic_templates for mapping
    def initialize(value)
      @hash = normalize(value)
    end

    def merge!(value)
      @hash = HashUtils.deep_merge(@hash, normalize(value))
    end

    def []=(key, value)
      merge!(key => value)
    end

    def to_a
      @hash.map do |name, value|
        { name => value }
      end
    end

    def any?
      @hash.any?
    end

    def dup
      self.class.new(@hash.dup)
    end

    private

    def normalize(value)
      case value
      when Array
        value.map { |v| normalize(v) }.reduce(&:merge)
      when Hash
        HashUtils.deep_transform_keys(value, &:to_sym)
      end || {}
    end
  end
end
