# frozen_string_literal: true

module Esse
  class ClientProxy
    module InstanceMethods
      # Returns results matching a query.
      def search(index:, **options)
        definition = options.merge(
          index: index,
        )

        Esse::Events.instrument('elasticsearch.search') do |payload|
          payload[:request] = definition
          payload[:response] = coerce_exception { client.search(definition) }
        end
      end

      # Allows to retrieve a large numbers of results from a single search request.
      #
      # @param [Time] :scroll Specify how long a consistent view of the index should be maintained for scrolled search
      # @param [Boolean] :rest_total_hits_as_int Indicates whether hits.total should be rendered as an integer or an object in the rest search response
      # @param [Hash] :body The scroll ID
      def scroll(scroll:, **definition)
        unless definition[:body]
          raise ArgumentError, 'scroll search must have a :body with the :scroll_id'
        end
        Esse::Events.instrument('elasticsearch.search') do |payload|
          payload[:request] = definition
          payload[:response] = coerce_exception { client.scroll(scroll: scroll, **definition) }
        end
      end

      # Explicitly clears the search context for a scroll.
      #
      # @param [Hash] :body Body with the "scroll_id" (string or array of strings) Scroll IDs to clear.
      #   To clear all scroll IDs, use _all.
      def clear_scroll(body:, **options)
        coerce_exception { client.clear_scroll(body: body, **options) }
      end
    end

    include InstanceMethods
  end
end
