# frozen_string_literal: true

module Esse
  class Index
    module ClassMethods
      # @param query_or_payload [String,Hash] The search request definition or query in the Lucene query string syntax
      # @param kwargs [Hash] The options to pass to the search.
      def search(*args, &block)
        query_or_payload = args.shift
        kwargs = args.last.is_a?(Hash) ? args.pop : {}

        if query_or_payload.respond_to?(:to_hash) && (hash = query_or_payload.to_hash) && (hash.key?(:body) || hash.key?('body') || hash.key?(:q) || hash.key?('q'))
          kwargs.merge!(hash.transform_keys(&:to_sym))
        elsif query_or_payload.respond_to?(:to_hash)
          kwargs[:body] = query_or_payload.to_hash
        elsif query_or_payload.is_a?(String) && query_or_payload =~ /^\s*{/
          kwargs[:body] = MultiJson.load(query_or_payload)
        elsif query_or_payload.is_a?(String)
          kwargs[:q] = query_or_payload
        end
        cluster.search(self, **kwargs, &block)
      end
    end

    extend ClassMethods
  end
end
