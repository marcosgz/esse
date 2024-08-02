# frozen_string_literal: true

module Esse
  class Transport
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
        throw_error_when_readonly!

        Esse::Events.instrument('elasticsearch.create_index') do |payload|
          payload[:request] = opts = options.merge(index: index)
          payload[:response] = response = coerce_exception { client.indices.create(**opts) }
          if response && response['acknowledged']
            coerce_exception do
              cluster.wait_for_status!(status: (wait_for_status || cluster.wait_for_status), index: index)
            end
          end
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
          payload[:request] = opts = options.merge(index: index)
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
        throw_error_when_readonly!

        Esse::Events.instrument('elasticsearch.delete_index') do |payload|
          payload[:request] = opts = options.merge(index: index)
          payload[:response] = response = coerce_exception { client.indices.delete(**opts) }
          if response && response['acknowledged']
            coerce_exception do
              cluster.wait_for_status!(status: (wait_for_status || cluster.wait_for_status), index: index)
            end
          end
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
        throw_error_when_readonly!

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
        throw_error_when_readonly!

        Esse::Events.instrument('elasticsearch.close') do |payload|
          payload[:request] = attributes = options.merge(index: index)
          payload[:response] = coerce_exception { client.indices.close(**attributes) }
        end
      end

      # Performs the refresh operation in one or more indices.
      #
      # @option options [List] :index A comma-separated list of index names; use `_all` or empty string to perform the operation on all indices
      # @option options [Boolean] :ignore_unavailable Whether specified concrete indices should be ignored when unavailable (missing or closed)
      # @option options [Boolean] :allow_no_indices Whether to ignore if a wildcard indices expression resolves into no concrete indices. (This includes `_all` string or when no indices have been specified)
      # @option options [String] :expand_wildcards Whether to expand wildcard expression to concrete indices that are open, closed or both. (options: open, closed, hidden, none, all)
      # @option options [Hash] :headers Custom HTTP headers
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-refresh.html
      def refresh(index:, **options)
        throw_error_when_readonly!

        Esse::Events.instrument('elasticsearch.refresh') do |payload|
          payload[:request] = attributes = options.merge(index: index)
          payload[:response] = coerce_exception { client.indices.refresh(**attributes) }
        end
      end

      # Updates the index mappings.
      #
      # @option options [List] :index A comma-separated list of index names the mapping should be added to (supports wildcards); use `_all` or omit to add the mapping on all indices.
      # @option options [Time] :timeout Explicit operation timeout
      # @option options [Time] :master_timeout Specify timeout for connection to master
      # @option options [Boolean] :ignore_unavailable Whether specified concrete indices should be ignored when unavailable (missing or closed)
      # @option options [Boolean] :allow_no_indices Whether to ignore if a wildcard indices expression resolves into no concrete indices. (This includes `_all` string or when no indices have been specified)
      # @option options [String] :expand_wildcards Whether to expand wildcard expression to concrete indices that are open, closed or both. (options: open, closed, hidden, none, all)
      # @option options [Boolean] :write_index_only When true, applies mappings only to the write index of an alias or data stream
      # @option options [Hash] :headers Custom HTTP headers
      # @option options [Hash] :body The mapping definition (*Required*)
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-put-mapping.html
      def update_mapping(index:, body:, **options)
        throw_error_when_readonly!

        Esse::Events.instrument('elasticsearch.update_mapping') do |payload|
          payload[:request] = opts = options.merge(index: index, body: body)
          payload[:response] = coerce_exception { client.indices.put_mapping(**opts) }
        end
      end

      # Updates the index settings.
      #
      # @option options [List] :index A comma-separated list of index names; use `_all` or empty string to perform the operation on all indices
      # @option options [Time] :master_timeout Specify timeout for connection to master
      # @option options [Time] :timeout Explicit operation timeout
      # @option options [Boolean] :preserve_existing Whether to update existing settings. If set to `true` existing settings on an index remain unchanged, the default is `false`
      # @option options [Boolean] :ignore_unavailable Whether specified concrete indices should be ignored when unavailable (missing or closed)
      # @option options [Boolean] :allow_no_indices Whether to ignore if a wildcard indices expression resolves into no concrete indices. (This includes `_all` string or when no indices have been specified)
      # @option options [String] :expand_wildcards Whether to expand wildcard expression to concrete indices that are open, closed or both. (options: open, closed, hidden, none, all)
      # @option options [Boolean] :flat_settings Return settings in flat format (default: false)
      # @option options [Hash] :headers Custom HTTP headers
      # @option options [Hash] :body The index settings to be updated (*Required*)
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-update-settings.html
      def update_settings(index:, body:, **options)
        throw_error_when_readonly!

        Esse::Events.instrument('elasticsearch.update_settings') do |payload|
          payload[:request] = opts = options.merge(index: index, body: body)
          payload[:response] = coerce_exception { client.indices.put_settings(**opts) }
        end
      end

      # Allows to copy documents from one index to another, optionally filtering the source
      # documents by a query, changing the destination index settings, or fetching the
      # documents from a remote cluster.
      #
      # @option arguments [Boolean] :refresh Should the affected indexes be refreshed?
      # @option arguments [Time] :timeout Time each individual bulk request should wait for shards that are unavailable.
      # @option arguments [String] :wait_for_active_shards Sets the number of shard copies that must be active before proceeding with the reindex operation. Defaults to 1, meaning the primary shard only. Set to `all` for all shard copies, otherwise set to any non-negative value less than or equal to the total number of copies for the shard (number of replicas + 1)
      # @option arguments [Boolean] :wait_for_completion Should the request should block until the reindex is complete.
      # @option arguments [Number] :requests_per_second The throttle to set on this request in sub-requests per second. -1 means no throttle.
      # @option arguments [Time] :scroll Control how long to keep the search context alive
      # @option arguments [Number|string] :slices The number of slices this task should be divided into. Defaults to 1, meaning the task isn't sliced into subtasks. Can be set to `auto`.
      # @option arguments [Number] :max_docs Maximum number of documents to process (default: all documents)
      # @option arguments [Hash] :headers Custom HTTP headers
      # @option arguments [Hash] :body The search definition using the Query DSL and the prototype for the index request. (*Required*)
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html
      def reindex(body:, **options)
        throw_error_when_readonly!

        Esse::Events.instrument('elasticsearch.reindex') do |payload|
          payload[:request] = opts = options.merge(body: body)
          payload[:response] = coerce_exception { client.reindex(**opts) }
        end
      end

      # Performs an update on every document in the index without changing the source,
      # for example to pick up a mapping change.
      #
      # @option arguments [List] :index A comma-separated list of index names to search; use `_all` or empty string to perform the operation on all indices (*Required*)
      # @option arguments [String] :analyzer The analyzer to use for the query string
      # @option arguments [Boolean] :analyze_wildcard Specify whether wildcard and prefix queries should be analyzed (default: false)
      # @option arguments [String] :default_operator The default operator for query string query (AND or OR) (options: AND, OR)
      # @option arguments [String] :df The field to use as default where no field prefix is given in the query string
      # @option arguments [Number] :from Starting offset (default: 0)
      # @option arguments [Boolean] :ignore_unavailable Whether specified concrete indices should be ignored when unavailable (missing or closed)
      # @option arguments [Boolean] :allow_no_indices Whether to ignore if a wildcard indices expression resolves into no concrete indices. (This includes `_all` string or when no indices have been specified)
      # @option arguments [String] :conflicts What to do when the update by query hits version conflicts? (options: abort, proceed)
      # @option arguments [String] :expand_wildcards Whether to expand wildcard expression to concrete indices that are open, closed or both. (options: open, closed, hidden, none, all)
      # @option arguments [Boolean] :lenient Specify whether format-based query failures (such as providing text to a numeric field) should be ignored
      # @option arguments [String] :pipeline Ingest pipeline to set on index requests made by this action. (default: none)
      # @option arguments [String] :preference Specify the node or shard the operation should be performed on (default: random)
      # @option arguments [String] :q Query in the Lucene query string syntax
      # @option arguments [List] :routing A comma-separated list of specific routing values
      # @option arguments [Time] :scroll Specify how long a consistent view of the index should be maintained for scrolled search
      # @option arguments [String] :search_type Search operation type (options: query_then_fetch, dfs_query_then_fetch)
      # @option arguments [Time] :search_timeout Explicit timeout for each search request. Defaults to no timeout.
      # @option arguments [Number] :size Deprecated, please use `max_docs` instead
      # @option arguments [Number] :max_docs Maximum number of documents to process (default: all documents)
      # @option arguments [List] :sort A comma-separated list of <field>:<direction> pairs
      # @option arguments [List] :_source True or false to return the _source field or not, or a list of fields to return
      # @option arguments [List] :_source_excludes A list of fields to exclude from the returned _source field
      # @option arguments [List] :_source_includes A list of fields to extract and return from the _source field
      # @option arguments [Number] :terminate_after The maximum number of documents to collect for each shard, upon reaching which the query execution will terminate early.
      # @option arguments [List] :stats Specific 'tag' of the request for logging and statistical purposes
      # @option arguments [Boolean] :version Specify whether to return document version as part of a hit
      # @option arguments [Boolean] :version_type Should the document increment the version number (internal) on hit or not (reindex)
      # @option arguments [Boolean] :request_cache Specify if request cache should be used for this request or not, defaults to index level setting
      # @option arguments [Boolean] :refresh Should the affected indexes be refreshed?
      # @option arguments [Time] :timeout Time each individual bulk request should wait for shards that are unavailable.
      # @option arguments [String] :wait_for_active_shards Sets the number of shard copies that must be active before proceeding with the update by query operation. Defaults to 1, meaning the primary shard only. Set to `all` for all shard copies, otherwise set to any non-negative value less than or equal to the total number of copies for the shard (number of replicas + 1)
      # @option arguments [Number] :scroll_size Size on the scroll request powering the update by query
      # @option arguments [Boolean] :wait_for_completion Should the request should block until the update by query operation is complete.
      # @option arguments [Number] :requests_per_second The throttle to set on this request in sub-requests per second. -1 means no throttle.
      # @option arguments [Number|string] :slices The number of slices this task should be divided into. Defaults to 1, meaning the task isn't sliced into subtasks. Can be set to `auto`.
      # @option arguments [Hash] :headers Custom HTTP headers
      # @option arguments [Hash] :body The search definition using the Query DSL
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-update-by-query.html
      def update_by_query(index:, **options)
        throw_error_when_readonly!

        Esse::Events.instrument('elasticsearch.update_by_query') do |payload|
          payload[:request] = opts = options.merge(index: index)
          payload[:response] = coerce_exception { client.update_by_query(**opts) }
        end
      end
    end

    include InstanceMethods
  end
end
