# frozen_string_literal: true

require_relative 'query/dsl'
module Esse
  module Search
    class Query
      include DSL
      attr_reader :transport, :definition

      # @param transport [Esse::Transport] The client proxy to use for the query
      # @param indices [<Array<Esse::Index, String>] The class of the index to search or the index name
      # @param definition [Hash] The options to pass to the search.
      def initialize(transport, *indices, suffix: nil, **definition, &_block)
        @transport = transport
        @definition = definition
        @definition[:index] = self.class.normalize_indices(*indices, suffix: suffix) if indices.size > 0
      end

      def self.normalize_indices(*indices, suffix: nil)
        indices.map do |index|
          if index.is_a?(Class) && index < Esse::Index
            index.index_name(suffix: suffix)
          elsif index.is_a?(String) || index.is_a?(Symbol)
            [index, suffix].compact.join('_')
          else
            raise ArgumentError, format('Invalid index type: %<index>p. It should be a Esse::Index class or a String index name', index: index)
          end
        end.join(',')
      end

      def response
        @response ||= execute_search_query!
      end

      def results
        return paginated_results if respond_to?(:paginated_results, true)

        response.hits
      end

      def scroll_hits(batch_size: 1_000, scroll: '1m')
        response = execute_search_query!(size: batch_size, scroll: scroll)
        scroll_id = response.raw_response['scroll_id'] || response.raw_response['_scroll_id']
        fetched = 0
        total = response.total

        loop do
          fetched += response.hits.size
          yield(response.hits) if response.hits.any?
          break if fetched >= total
          break unless scroll_id
          response = execute_scroll_query(scroll: scroll, scroll_id: scroll_id)
          scroll_id = response.raw_response['scroll_id'] || response.raw_response['_scroll_id']
        end
      ensure
        begin
          transport.clear_scroll(body: {scroll_id: scroll_id}) if scroll_id
        rescue Esse::Transport::NotFoundError
        end
      end

      def search_after_hits(batch_size: 1_000)
        body = HashUtils.deep_dup(definition.fetch(:body, {}))
        body[:size] = batch_size
        body.delete(:from)
        body.delete('from')

        unless body.key?(:sort) || body.key?('sort')
          raise ArgumentError, 'The query body must include a :sort to use search_after'
        end

        loop do
          response = execute_search_query!(body: body)
          break if response.hits.empty?

          yield(response.hits)

          last_sort = response.hits.last['sort']
          break unless last_sort
          break if response.hits.size < batch_size

          body[:search_after] = last_sort
        end
      end

      def reset!
        @response = nil
      end

      private

      def execute_search_query!(**execution_options)
        resp, err = nil
        Esse::Events.instrument('elasticsearch.execute_search_query') do |payload|
          payload[:query_definition] = definition
          begin
            resp = Response.new(self, transport.search(**definition, **execution_options))
          rescue => e
            err = e
          end
          payload[:error] = err if err
          payload[:response] = resp
        end
        raise err if err

        resp
      end

      def execute_scroll_query(scroll:, scroll_id:)
        resp, err = nil
        Esse::Events.instrument('elasticsearch.execute_search_query') do |payload|
          payload[:query_definition] = definition
          begin
            resp = Response.new(self, transport.scroll(scroll: scroll, body: { scroll_id: scroll_id }))
          rescue => e
            err = e
          end
          payload[:error] = err if err
          payload[:response] = resp
        end
        raise err if err

        resp
      end
    end
  end
end
