# frozen_string_literal: true

module Esse
  module Search
    class Response
      include Enumerable
      extend Forwardable

      def_delegators :hits, :each, :size, :empty?
      attr_reader :query, :raw_response, :options

      # @param [Esse::Search::Query] query The search query
      # @param [Hash] raw_response The raw response from Elasticsearch
      # @param [Hash] options The options passed to the search
      def initialize(query, raw_response, **options)
        @query = query
        @raw_response = raw_response
        @options = options
      end

      def shards
        raw_response['_shards']
      end

      def aggregations
        raw_response['aggregations']
      end

      def suggestions
        raw_response['suggest']
      end

      def hits
        raw_response.dig('hits', 'hits') || []
      end

      def total
        if raw_response.dig('hits', 'total').respond_to?(:keys)
          raw_response.dig('hits', 'total', 'value')
        else
          raw_response.dig('hits', 'total')
        end.to_i
      end
    end
  end
end
