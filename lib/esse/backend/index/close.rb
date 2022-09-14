# frozen_string_literal: true

module Esse
  module Backend
    class Index
      module InstanceMethods
        # Close an index (keep the data on disk, but deny operations with the index).
        #
        # @option options [String, nil] :suffix The index suffix. Defaults to the index_version.
        #   Use nil if you want to check existence of the `index_name` index or alias.
        # @option options [String] :expand_wildcards Whether to expand wildcard expression to concrete indices that
        #   are open, closed or both. (options: open, closed)
        # @option options [String] :ignore_indices When performed on multiple indices, allows to ignore
        #   `missing` ones (options: none, missing) @until 1.0
        # @option options [Boolean] :ignore_unavailable Whether specified concrete indices should be ignored when
        #   unavailable (missing, closed, etc)
        # @option options [Time] :timeout Explicit operation timeout
        # @raise [Esse::Transport::ServerError]
        #   in case of failure
        # @return [Hash] the elasticsearch response
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/master/indices-open-close.html
        def close!(suffix: index_version, **options)
          Esse::Events.instrument('elasticsearch.close') do |payload|
            payload[:request] = attributes = options.merge(index: index_name(suffix: suffix))
            payload[:response] = coerce_exception { client.indices.close(**attributes) }
          end
        end

        # Close an index (keep the data on disk, but deny operations with the index).
        #
        # @option options [String, nil] :suffix The index suffix. Defaults to the index_version.
        #   Use nil if you want to check existence of the `index_name` index or alias.
        # @option options [String] :expand_wildcards Whether to expand wildcard expression to concrete indices that
        #   are open, closed or both. (options: open, closed)
        # @option options [String] :ignore_indices When performed on multiple indices, allows to ignore
        #   `missing` ones (options: none, missing) @until 1.0
        # @option options [Boolean] :ignore_unavailable Whether specified concrete indices should be ignored when
        #   unavailable (missing, closed, etc)
        # @option options [Time] :timeout Explicit operation timeout
        # @return [Hash] the elasticsearch response, or an hash with 'errors' as true in case of failure
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/master/indices-open-close.html
        def close(suffix: index_version, **options)
          close!(suffix: suffix, **options)
        rescue Esse::Transport::ServerError
          { 'errors' => true }
        end
      end

      include InstanceMethods
    end
  end
end
