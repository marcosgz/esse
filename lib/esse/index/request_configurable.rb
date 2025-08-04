# frozen_string_literal: true

module Esse
  class Index
    module RequestConfigurable
      OPERATIONS = %i[index create update delete].freeze
      BULK_OPERATIONS_AND_PARAMS = {
        index: %i[_index _type routing if_primary_term if_seq_no version version_type dynamic_templates pipeline require_alias],
        create: %i[_index _type routing if_primary_term if_seq_no version version_type dynamic_templates pipeline require_alias],
        update: %i[_index _type routing if_primary_term if_seq_no version version_type require_alias retry_on_conflict],
        delete: %i[_index _type routing if_primary_term if_seq_no version version_type],
      }.freeze

      def self.extended(base)
        base.extend DSL
      end

      class RequestParams
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

      module DSL
        def request_params(*operations, **params, &block)
          operations.each do |operation|
            raise ArgumentError, "Invalid operation: #{operation}" unless OPERATIONS.include?(operation)

            @request_params ||= Container.new
            @request_params.add(operation, RequestParams.new(operation, params, &block))
          end

          self
        end

        def request_params_for(operation, doc, bulk: false)
          return {} unless request_params_for?(operation)

          params = @request_params.retrieve(operation, doc)

          if bulk && BULK_OPERATIONS_AND_PARAMS.key?(operation)
            params.slice(*BULK_OPERATIONS_AND_PARAMS[operation])
          else
            params
          end
        end

        def request_params_for?(operation)
          return false unless @request_params

          @request_params.key?(operation)
        end
      end
    end

    extend RequestConfigurable
  end
end
