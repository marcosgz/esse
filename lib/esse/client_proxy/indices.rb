# frozen_string_literal: true

module Esse
  class ClientProxy
    module InstanceMethods
      # Creates an index with optional settings and mappings.
      #
      # @param options [Hash] Options hash
      # @option [String] :index The name of the index
      # @option [String] :wait_for_active_shards Set the number of active shards to wait for before the operation returns.
      # @option [Time] :timeout Explicit operation timeout
      # @option [Time] :master_timeout Specify timeout for connection to master
      # @option [Hash] :headers Custom HTTP headers
      # @option [Hash] :body The configuration for the index (`settings` and `mappings`)
      # @option [String] :wait_for_status Wait until cluster is in a specific state (options: green, yellow, red)
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-create-index.html
      def create_index(index:, wait_for_status: nil, **options)
        Esse::Events.instrument('elasticsearch.create_index') do |payload|
          payload[:request] = opts = options.merge(**options, index: index)
          payload[:response] = response = coerce_exception { client.indices.create(**opts) }
          coerce_exception do
            cluster.wait_for_status!(status: (wait_for_status || cluster.wait_for_status), index: index)
          end if response && response['acknowledged']
          response
        end
      end

      # Returns information about whether a particular index exists.
      #
      # @option [List] :index A comma-separated list of index names
      # @option [Boolean] :local Return local information, do not retrieve the state from master node (default: false)
      # @option [Boolean] :ignore_unavailable Ignore unavailable indexes (default: false)
      # @option [Boolean] :allow_no_indices Ignore if a wildcard expression resolves to no concrete indices (default: false)
      # @option [String] :expand_wildcards Whether wildcard expressions should get expanded to open or closed indices (default: open) (options: open, closed, hidden, none, all)
      # @option [Boolean] :flat_settings Return settings in flat format (default: false)
      # @option [Boolean] :include_defaults Whether to return all default setting for each of the indices.
      # @option [Hash] :headers Custom HTTP headers
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-exists.html
      def index_exist?(index:, **options)
        Esse::Events.instrument('elasticsearch.index_exist') do |payload|
          payload[:request] = opts = options.merge(**options, index: index)
          payload[:response] = coerce_exception { client.indices.exists(**opts) }
        end
      end

      # Deletes an index.
      #
      # @option [List] :index A comma-separated list of indices to delete; use `_all` or `*` string to delete all indices
      # @option [Time] :timeout Explicit operation timeout
      # @option [Time] :master_timeout Specify timeout for connection to master
      # @option [Boolean] :ignore_unavailable Ignore unavailable indexes (default: false)
      # @option [Boolean] :allow_no_indices Ignore if a wildcard expression resolves to no concrete indices (default: false)
      # @option [String] :expand_wildcards Whether wildcard expressions should get expanded to open, closed, or hidden indices (options: open, closed, hidden, none, all)
      # @option [Hash] :headers Custom HTTP headers
      # @option [String] :wait_for_status Wait until cluster is in a specific state (options: green, yellow, red)
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-delete-index.html
      def delete_index(index:, wait_for_status: nil, **options)
        Esse::Events.instrument('elasticsearch.delete_index') do |payload|
          payload[:request] = opts = options.merge(index: index)
          payload[:response] = response = coerce_exception { client.indices.delete(**opts) }
          coerce_exception do
            cluster.wait_for_status!(status: (wait_for_status || cluster.wait_for_status), index: index)
          end if response && response['acknowledged']
          response
        end
      end

      # Open a previously closed index
      #
      # @option options [List] :index A comma separated list of indices to open
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
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/master/indices-open-open.html
      def open(index:, **options)
        Esse::Events.instrument('elasticsearch.open') do |payload|
          payload[:request] = attributes = options.merge(index: index)
          payload[:response] = coerce_exception { client.indices.open(**attributes) }
        end
      end

      # Close an index (keep the data on disk, but deny operations with the index).
      #
      # @option options [List] :index A comma separated list of indices to open
      # @option options [String] :expand_wildcards Whether to expand wildcard expression to concrete indices that
      #   are open, closed or both. (options: open, closed)
      # @option options [String] :ignore_indices When performed on multiple indices, allows to ignore
      #   `missing` ones (options: none, missing) @until 1.0
      # @option options [Boolean] :ignore_unavailable Whether specified concrete indices should be ignored when
      #   unavailable (missing, closed, etc)
      # @option options [Time] :timeout Explicit operation timeout
      # @raise [Esse::Transport::ServerError] in case of failure
      # @return [Hash] the elasticsearch response
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/master/indices-open-close.html
      def close(index:, **options)
        Esse::Events.instrument('elasticsearch.close') do |payload|
          payload[:request] = attributes = options.merge(index: index)
          payload[:response] = coerce_exception { client.indices.close(**attributes) }
        end
      end

      # Performs the refresh operation in one or more indices.
      #
      # @note The refresh operation can adversely affect indexing throughput when used too frequently.
      # @param :suffix [String, nil] :suffix The index suffix. Defaults to the index_version.
      #   A uniq index name will be generated if one index already exist with the given alias.
      # @param options [Hash] Options hash
      # @raise [Esse::Transport::ServerError]
      #   in case of failure
      # @return [Hash] the elasticsearch response
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/master/indices-refresh.html
      def refresh(index:, **options)
        Esse::Events.instrument('elasticsearch.refresh') do |payload|
          payload[:request] = attributes = options.merge(index: index)
          payload[:response] = coerce_exception { client.indices.refresh(**attributes) }
        end
      end
    end

    include InstanceMethods
  end
end
