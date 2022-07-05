# frozen_string_literal: true

module Esse
  module Search
    class Query
      attr_reader :index, :options, :definition

      # @param index [Esse::Index] The class of the index to search.
      # @param query_or_payload [String,Hash] The search request definition or query in the Lucene query string syntax
      # @param kwargs [Hash] The options to pass to the search.
      def initialize(index, query_or_payload, **kwargs, &_block)
        @index = index
        @options = kwargs

        @definition = {}
        if query_or_payload.respond_to?(:to_hash)
          @definition[:body] = query_or_payload.to_hash
        elsif query_or_payload.is_a?(String) && query_or_payload =~ /^\s*{/
          @definition[:body] = MultiJson.load(query_or_payload)
        else
          @definition[:q] = query_or_payload
        end
      end

      def response
        @response ||= begin
          resp = index.elasticsearch.search(**definition, **options)
          Response.new(self, resp)
        end
      end

      private

      def raw_limit_value
        definition.dig(:body, :size) || definition.dig(:body, 'size') || definition.dig(:size) || definition.dig('size') || options[:size]
      end

      def raw_offset_value
        definition.dig(:body, :from) || definition.dig(:body, 'from') || definition.dig(:from) || definition.dig('from') || options[:from]
      end
    end
  end
end
