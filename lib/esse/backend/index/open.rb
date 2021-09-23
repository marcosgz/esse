# frozen_string_literal: true

module Esse
  module Backend
    class Index
      module InstanceMethods
        # Open a previously closed index
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
        # @raise [Elasticsearch::Transport::Transport::Errors::BadRequest, Elasticsearch::Transport::Transport::Errors::NotFound]
        #   in case of failure
        # @return [Hash] the elasticsearch response
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/master/indices-open-open.html
        def open!(suffix: index_version, **options)
          Esse::Events.instrument('elasticsearch.open') do |payload|
            payload[:request] = attributes = options.merge(index: index_name(suffix: suffix))
            payload[:response] = client.indices.open(**attributes)
          end
        end

        # Open a previously closed index
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
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/master/indices-open-open.html
        def open(suffix: index_version, **options)
          open!(suffix: suffix, **options)
        rescue Elasticsearch::Transport::Transport::ServerError
          { 'errors' => true }
        end
      end

      include InstanceMethods
    end
  end
end
