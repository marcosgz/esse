# frozen_string_literal: true

module Esse
  module RequestConfigurable
    OPERATIONS = %i[
      index
      create
      update
      delete
      bulk
      bulk_update
      bulk_delete
      bulk_create
      bulk_index
      search
    ].freeze

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
    end

    class RequestEntry
      attr_reader :operation, :hash, :block

      def initialize(operation, hash = {}, &block)
        @operation = operation
        @hash = hash.transform_keys(&:to_sym)
        @block = block
      end

      # @param doc [Esse::Document] the document to apply the request parameters to
      # @return [Hash] the request parameters for the operation
      # @raise [ArgumentError] if the result of the block is not a Hash
      def call(doc)
        return hash unless block

        result = block.call(doc) || {}
        raise ArgumentError, "Expected a Hash, got #{result.class}" unless result.is_a?(Hash)

        hash.merge(result.transform_keys(&:to_sym))
      end
    end

    class RequestParams < RequestEntry
    end

    class RequestBody < RequestEntry
    end

    class Container
      def initialize
        @mutex = Mutex.new
        @entries = {}.freeze
      end

      def add(operation, entry)
        @mutex.synchronize do
          hash = @entries.dup
          arr = (hash[operation] || []).dup
          arr << entry
          hash[operation] = arr.freeze
          @entries = hash.freeze
        end
      end

      def key?(operation)
        @entries.key?(operation)
      end

      def retrieve(operation, doc)
        return {} unless @entries[operation]

        @entries[operation].each_with_object({}) do |entry, hash|
          hash.merge!(entry.call(doc))
        end
      end
    end

    module ClassMethods
      def request_params(*operations, **params, &block)
        operations.each do |operation|
          raise ArgumentError, "Invalid operation: #{operation}" unless OPERATIONS.include?(operation)

          @_request_params ||= Container.new
          @_request_params.add(operation, RequestParams.new(operation, params, &block))
        end

        self
      end

      def request_body(*operations, **params, &block)
        operations.each do |operation|
          raise ArgumentError, "Invalid operation: #{operation}" unless OPERATIONS.include?(operation)

          @_request_body ||= Container.new
          @_request_body.add(operation, RequestBody.new(operation, params, &block))
        end

        self
      end

      def request_params_for(operation, doc)
        return {} unless request_params_for?(operation)

        @_request_params.retrieve(operation, doc)
      end

      def request_params_for?(operation)
        return false unless @_request_params

        @_request_params.key?(operation)
      end

      def request_body_for(operation, doc)
        return {} unless request_body_for?(operation)

        @_request_body.retrieve(operation, doc)
      end

      def request_body_for?(operation)
        return false unless @_request_body

        @_request_body.key?(operation)
      end
    end

    module InstanceMethods
      def request_params_for(operation)
        self.class.request_params_for(operation, self)
      end

      def request_params_for?(operation)
        self.class.request_params_for?(operation)
      end

      def request_body_for(operation)
        self.class.request_body_for(operation, self)
      end

      def request_body_for?(operation)
        self.class.request_body_for?(operation)
      end
    end
  end
end
