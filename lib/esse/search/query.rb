# frozen_string_literal: true

module Esse
  module Search
    class Query
      attr_reader :client_proxy, :definition

      # @param client_proxy [Esse::ClientProxy] The client proxy to use for the query
      # @param indices [<Array<Esse::Index, String>] The class of the index to search or the index name
      # @param definition [Hash] The options to pass to the search.
      def initialize(client_proxy, *indices, suffix: nil, **definition, &_block)
        @client_proxy = client_proxy
        @definition = definition
        @definition[:index] = indices.map do |index|
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

      private

      def execute_search_query!
        resp, err = nil
        Esse::Events.instrument('elasticsearch.execute_search_query') do |payload|
          payload[:query] = self
          begin
            resp = Response.new(self, client_proxy.search(**definition))
          rescue => e
            err = e
          end
          payload[:error] = err if err
          payload[:response] = resp
        end
        raise err if err

        resp
      end

      def reset!
        @response = nil
      end

      def raw_limit_value
        definition.dig(:body, :size) || definition.dig(:body, 'size') || definition.dig(:size) || definition.dig('size')
      end

      def raw_offset_value
        definition.dig(:body, :from) || definition.dig(:body, 'from') || definition.dig(:from) || definition.dig('from')
      end
    end
  end
end
