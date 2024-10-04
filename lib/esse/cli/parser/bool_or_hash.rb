# frozen_string_literal: true

module Esse
  module CLI
    module Parser
      FALSEY = [false, 'false', 'FALSE', 'f', 'F'].freeze
      TRUTHY = [true, 'true', 'TRUE', 't', 'T'].freeze
      HASH_MATCHER = /([\w\.\-]+)\:([^\s]+)/.freeze
      HASH_SEPARATOR = /[\s]+/.freeze
      ARRAY_SEPARATOR = /[\,]+/.freeze

      class BoolOrHash
        def initialize(key, default: nil)
          @key = key
          @default = default
        end

        def parse(input)
          return true if TRUTHY.include?(input)
          return false if FALSEY.include?(input)
          return input if input.is_a?(Hash)
          return @default if input.nil?
          return true if @key.to_s == input
          return @default unless HASH_MATCHER.match?(input)

          compact_hash = input.to_s.split(HASH_SEPARATOR).each_with_object({}) do |pair, hash|
            key, val = pair.match(HASH_MATCHER).captures
            hash[key.to_sym] = may_array(val)
          end
          return @default if compact_hash.empty?

          Esse::HashUtils.explode_keys(compact_hash)
        end

        private

        def may_array(value)
          return value unless ARRAY_SEPARATOR.match?(value)

          value.split(ARRAY_SEPARATOR)
        end
      end
    end
  end
end
