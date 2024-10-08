# frozen_string_literal: true

module Esse
  class Transport
    module InstanceMethods
      # Returns a document.
      #
      # @option [String] :id The document ID
      # @option [String] :index The name of the index
      # @option [Boolean] :force_synthetic_source Should this request force synthetic _source? Use this to test if the mapping supports synthetic _source and to get a sense of the worst case performance. Fetches with this enabled will be slower the enabling synthetic source natively in the index.
      # @option [List] :stored_fields A comma-separated list of stored fields to return in the response
      # @option [String] :preference Specify the node or shard the operation should be performed on (default: random)
      # @option [Boolean] :realtime Specify whether to perform the operation in realtime or search mode
      # @option [Boolean] :refresh Refresh the shard containing the document before performing the operation
      # @option [String] :routing Specific routing value
      # @option [List] :_source True or false to return the _source field or not, or a list of fields to return
      # @option [List] :_source_excludes A list of fields to exclude from the returned _source field
      # @option [List] :_source_includes A list of fields to extract and return from the _source field
      # @option [Number] :version Explicit version number for concurrency control
      # @option [String] :version_type Specific version type (options: internal, external, external_gte)
      # @option [Hash] :headers Custom HTTP headers
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-get.html
      #
      def get(id:, index:, **options)
        Esse::Events.instrument('elasticsearch.get') do |payload|
          payload[:request] = opts = options.merge(id: id, index: index)
          payload[:response] = coerce_exception { client.get(**opts) }
        end
      end

      # Returns information about whether a document exists in an index.
      #
      # @option [String] :id The document ID
      # @option [String] :index The name of the index
      # @option [List] :stored_fields A comma-separated list of stored fields to return in the response
      # @option [String] :preference Specify the node or shard the operation should be performed on (default: random)
      # @option [Boolean] :realtime Specify whether to perform the operation in realtime or search mode
      # @option [Boolean] :refresh Refresh the shard containing the document before performing the operation
      # @option [String] :routing Specific routing value
      # @option [List] :_source True or false to return the _source field or not, or a list of fields to return
      # @option [List] :_source_excludes A list of fields to exclude from the returned _source field
      # @option [List] :_source_includes A list of fields to extract and return from the _source field
      # @option [Number] :version Explicit version number for concurrency control
      # @option [String] :version_type Specific version type (options: internal, external, external_gte)
      # @option [Hash] :headers Custom HTTP headers
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-get.html
      #
      def exist?(id:, index:, **options)
        Esse::Events.instrument('elasticsearch.exist') do |payload|
          payload[:request] = opts = options.merge(id: id, index: index)
          payload[:response] = coerce_exception { client.exists(**opts) }
        end
      end

      # Returns number of documents matching a query.
      #
      # @option [List] :index A comma-separated list of indices to restrict the results
      # @option [Boolean] :ignore_unavailable Whether specified concrete indices should be ignored when unavailable (missing or closed)
      # @option [Boolean] :ignore_throttled Whether specified concrete, expanded or aliased indices should be ignored when throttled
      # @option [Boolean] :allow_no_indices Whether to ignore if a wildcard indices expression resolves into no concrete indices. (This includes `_all` string or when no indices have been specified)
      # @option [String] :expand_wildcards Whether to expand wildcard expression to concrete indices that are open, closed or both. (options: open, closed, hidden, none, all)
      # @option [Number] :min_score Include only documents with a specific `_score` value in the result
      # @option [String] :preference Specify the node or shard the operation should be performed on (default: random)
      # @option [List] :routing A comma-separated list of specific routing values
      # @option [String] :q Query in the Lucene query string syntax
      # @option [String] :analyzer The analyzer to use for the query string
      # @option [Boolean] :analyze_wildcard Specify whether wildcard and prefix queries should be analyzed (default: false)
      # @option [String] :default_operator The default operator for query string query (AND or OR) (options: AND, OR)
      # @option [String] :df The field to use as default where no field prefix is given in the query string
      # @option [Boolean] :lenient Specify whether format-based query failures (such as providing text to a numeric field) should be ignored
      # @option [Number] :terminate_after The maximum count for each shard, upon reaching which the query execution will terminate early
      # @option [Hash] :headers Custom HTTP headers
      # @option [Hash] :body A query to restrict the results specified with the Query DSL (optional)
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/search-count.html
      def count(index:, **options)
        Esse::Events.instrument('elasticsearch.count') do |payload|
          payload[:request] = opts = options.merge(index: index)
          payload[:response] = coerce_exception { client.count(**opts) }
        end
      end

      # Removes a document from the index.
      #
      # @option arguments [String] :id The document ID
      # @option arguments [String] :index The name of the index
      # @option arguments [String] :wait_for_active_shards Sets the number of shard copies that must be active before proceeding with the delete operation. Defaults to 1, meaning the primary shard only. Set to `all` for all shard copies, otherwise set to any non-negative value less than or equal to the total number of copies for the shard (number of replicas + 1)
      # @option arguments [String] :refresh If `true` then refresh the affected shards to make this operation visible to search, if `wait_for` then wait for a refresh to make this operation visible to search, if `false` (the default) then do nothing with refreshes. (options: true, false, wait_for)
      # @option arguments [String] :routing Specific routing value
      # @option arguments [Time] :timeout Explicit operation timeout
      # @option arguments [Number] :if_seq_no only perform the delete operation if the last operation that has changed the document has the specified sequence number
      # @option arguments [Number] :if_primary_term only perform the delete operation if the last operation that has changed the document has the specified primary term
      # @option arguments [Number] :version Explicit version number for concurrency control
      # @option arguments [String] :version_type Specific version type (options: internal, external, external_gte)
      # @option arguments [Hash] :headers Custom HTTP headers
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-delete.html
      def delete(id:, index:, **options)
        throw_error_when_readonly!

        Esse::Events.instrument('elasticsearch.delete') do |payload|
          payload[:request] = opts = options.merge(id: id, index: index)
          payload[:response] = coerce_exception { client.delete(**opts) }
        end
      end

      # Updates a document with a script or partial document.
      #
      # @option [String] :id Document ID
      # @option [String] :index The name of the index
      # @option [String] :wait_for_active_shards Sets the number of shard copies that must be active before proceeding with the update operation. Defaults to 1, meaning the primary shard only. Set to `all` for all shard copies, otherwise set to any non-negative value less than or equal to the total number of copies for the shard (number of replicas + 1)
      # @option [List] :_source True or false to return the _source field or not, or a list of fields to return
      # @option [List] :_source_excludes A list of fields to exclude from the returned _source field
      # @option [List] :_source_includes A list of fields to extract and return from the _source field
      # @option [String] :lang The script language (default: painless)
      # @option [String] :refresh If `true` then refresh the affected shards to make this operation visible to search, if `wait_for` then wait for a refresh to make this operation visible to search, if `false` (the default) then do nothing with refreshes. (options: true, false, wait_for)
      # @option [Number] :retry_on_conflict Specify how many times should the operation be retried when a conflict occurs (default: 0)
      # @option [String] :routing Specific routing value
      # @option [Time] :timeout Explicit operation timeout
      # @option [Number] :if_seq_no only perform the update operation if the last operation that has changed the document has the specified sequence number
      # @option [Number] :if_primary_term only perform the update operation if the last operation that has changed the document has the specified primary term
      # @option [Boolean] :require_alias When true, requires destination is an alias. Default is false
      # @option [Hash] :headers Custom HTTP headers
      # @option [Hash] :body The request definition requires either `script` or partial `doc` (*Required*)
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-update.html
      #
      def update(id:, index:, body:, **options)
        throw_error_when_readonly!

        Esse::Events.instrument('elasticsearch.update') do |payload|
          payload[:request] = opts = options.merge(id: id, index: index, body: body)
          payload[:response] = coerce_exception { client.update(**opts) }
        end
      end

      # Creates or updates a document in an index.
      #
      # @option [String] :id Document ID
      # @option [String] :index The name of the index
      # @option [String] :wait_for_active_shards Sets the number of shard copies that must be active before proceeding with the index operation. Defaults to 1, meaning the primary shard only. Set to `all` for all shard copies, otherwise set to any non-negative value less than or equal to the total number of copies for the shard (number of replicas + 1)
      # @option [String] :op_type Explicit operation type. Defaults to `index` for requests with an explicit document ID, and to `create`for requests without an explicit document ID (options: index, create)
      # @option [String] :refresh If `true` then refresh the affected shards to make this operation visible to search, if `wait_for` then wait for a refresh to make this operation visible to search, if `false` (the default) then do nothing with refreshes. (options: true, false, wait_for)
      # @option [String] :routing Specific routing value
      # @option [Time] :timeout Explicit operation timeout
      # @option [Number] :version Explicit version number for concurrency control
      # @option [String] :version_type Specific version type (options: internal, external, external_gte)
      # @option [Number] :if_seq_no only perform the index operation if the last operation that has changed the document has the specified sequence number
      # @option [Number] :if_primary_term only perform the index operation if the last operation that has changed the document has the specified primary term
      # @option [String] :pipeline The pipeline id to preprocess incoming documents with
      # @option [Boolean] :require_alias When true, requires destination to be an alias. Default is false
      # @option [Hash] :headers Custom HTTP headers
      # @option [Hash] :body The document (*Required*)
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-index_.html
      def index(id:, index:, body:, **options)
        throw_error_when_readonly!

        Esse::Events.instrument('elasticsearch.index') do |payload|
          payload[:request] = opts = options.merge(id: id, index: index, body: body)
          payload[:response] = coerce_exception { client.index(**opts) }
        end
      end

      # Allows to perform multiple index/update/delete operations in a single request.
      #
      # @option arguments [String] :index Default index for items which don't provide one
      # @option arguments [String] :wait_for_active_shards Sets the number of shard copies that must be active before proceeding with the bulk operation. Defaults to 1, meaning the primary shard only. Set to `all` for all shard copies, otherwise set to any non-negative value less than or equal to the total number of copies for the shard (number of replicas + 1)
      # @option arguments [String] :refresh If `true` then refresh the affected shards to make this operation visible to search, if `wait_for` then wait for a refresh to make this operation visible to search, if `false` (the default) then do nothing with refreshes. (options: true, false, wait_for)
      # @option arguments [String] :routing Specific routing value
      # @option arguments [Time] :timeout Explicit operation timeout
      # @option arguments [String] :type Default document type for items which don't provide one
      # @option arguments [List] :_source True or false to return the _source field or not, or default list of fields to return, can be overridden on each sub-request
      # @option arguments [List] :_source_excludes Default list of fields to exclude from the returned _source field, can be overridden on each sub-request
      # @option arguments [List] :_source_includes Default list of fields to extract and return from the _source field, can be overridden on each sub-request
      # @option arguments [String] :pipeline The pipeline id to preprocess incoming documents with
      # @option arguments [Boolean] :require_alias Sets require_alias for all incoming documents. Defaults to unset (false)
      # @option arguments [Hash] :headers Custom HTTP headers
      # @option arguments [String|Array] :body The operation definition and data (action-data pairs), separated by newlines. Array of Strings, Header/Data pairs,
      # or the conveniency "combined" format can be passed, refer to Elasticsearch::API::Utils.__bulkify documentation.
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html
      def bulk(body:, **options)
        throw_error_when_readonly!

        Esse::Events.instrument('elasticsearch.bulk') do |payload|
          payload[:request] = opts = options.merge(body: body)
          payload[:response] = response = coerce_exception { client.bulk(**opts) }
          yield(payload) if block_given? # Allow caller to add data to the payload of event
          response
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

      # Deletes documents matching the provided query.
      #
      # @option arguments [List] :index A comma-separated list of index names to search; use `_all` or empty string to perform the operation on all indices
      # @option arguments [String] :analyzer The analyzer to use for the query string
      # @option arguments [Boolean] :analyze_wildcard Specify whether wildcard and prefix queries should be analyzed (default: false)
      # @option arguments [String] :default_operator The default operator for query string query (AND or OR) (options: AND, OR)
      # @option arguments [String] :df The field to use as default where no field prefix is given in the query string
      # @option arguments [Number] :from Starting offset (default: 0)
      # @option arguments [Boolean] :ignore_unavailable Whether specified concrete indices should be ignored when unavailable (missing or closed)
      # @option arguments [Boolean] :allow_no_indices Whether to ignore if a wildcard indices expression resolves into no concrete indices. (This includes `_all` string or when no indices have been specified)
      # @option arguments [String] :conflicts What to do when the delete by query hits version conflicts? (options: abort, proceed)
      # @option arguments [String] :expand_wildcards Whether to expand wildcard expression to concrete indices that are open, closed or both. (options: open, closed, hidden, none, all)
      # @option arguments [Boolean] :lenient Specify whether format-based query failures (such as providing text to a numeric field) should be ignored
      # @option arguments [String] :preference Specify the node or shard the operation should be performed on (default: random)
      # @option arguments [String] :q Query in the Lucene query string syntax
      # @option arguments [List] :routing A comma-separated list of specific routing values
      # @option arguments [Time] :scroll Specify how long a consistent view of the index should be maintained for scrolled search
      # @option arguments [String] :search_type Search operation type (options: query_then_fetch, dfs_query_then_fetch)
      # @option arguments [Time] :search_timeout Explicit timeout for each search request. Defaults to no timeout.
      # @option arguments [Number] :max_docs Maximum number of documents to process (default: all documents)
      # @option arguments [List] :sort A comma-separated list of <field>:<direction> pairs
      # @option arguments [Number] :terminate_after The maximum number of documents to collect for each shard, upon reaching which the query execution will terminate early.
      # @option arguments [List] :stats Specific 'tag' of the request for logging and statistical purposes
      # @option arguments [Boolean] :version Specify whether to return document version as part of a hit
      # @option arguments [Boolean] :request_cache Specify if request cache should be used for this request or not, defaults to index level setting
      # @option arguments [Boolean] :refresh Should the affected indexes be refreshed?
      # @option arguments [Time] :timeout Time each individual bulk request should wait for shards that are unavailable.
      # @option arguments [String] :wait_for_active_shards Sets the number of shard copies that must be active before proceeding with the delete by query operation. Defaults to 1, meaning the primary shard only. Set to `all` for all shard copies, otherwise set to any non-negative value less than or equal to the total number of copies for the shard (number of replicas + 1)
      # @option arguments [Number] :scroll_size Size on the scroll request powering the delete by query
      # @option arguments [Boolean] :wait_for_completion Should the request should block until the delete by query is complete.
      # @option arguments [Number] :requests_per_second The throttle for this request in sub-requests per second. -1 means no throttle.
      # @option arguments [Number|string] :slices The number of slices this task should be divided into. Defaults to 1, meaning the task isn't sliced into subtasks. Can be set to `auto`.
      # @option arguments [Hash] :headers Custom HTTP headers
      # @option arguments [Hash] :body The search definition using the Query DSL (*Required*)
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-delete-by-query.html
      def delete_by_query(index:, **options)
        throw_error_when_readonly!

        Esse::Events.instrument('elasticsearch.delete_by_query') do |payload|
          payload[:request] = opts = options.merge(index: index)
          payload[:response] = coerce_exception { client.delete_by_query(**opts) }
        end
      end
    end

    include InstanceMethods
  end
end
