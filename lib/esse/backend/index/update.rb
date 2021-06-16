# frozen_string_literal: true

module Esse
  module Backend
    class Index
      module InstanceMethods
        # Create or update a mapping
        #
        # @option options [String] :type The name of the document type. This field is required for some elasticsearch versions
        # @option options [Boolean] :ignore_conflicts Specify whether to ignore conflicts while updating the mapping
        #   (default: false)
        # @option options [Boolean] :allow_no_indices Whether to ignore if a wildcard indices expression resolves into
        #   no concrete indices. (This includes `_all` string or when no indices have been specified)
        # @option options [String] :expand_wildcards Whether to expand wildcard expression to concrete indices that
        #   are open, closed or both. (options: open, closed)
        # @option options [String] :ignore_indices When performed on multiple indices, allows to ignore
        #   `missing` ones (options: none, missing) @until 1.0
        # @option options [Boolean] :ignore_unavailable Whether specified concrete indices should be ignored when
        #   unavailable (missing, closed, etc)
        # @option options [Boolean] :update_all_types Whether to update the mapping for all fields
        #   with the same name across all types
        # @option options [Time] :timeout Explicit operation timeout
        # @option options [Boolean] :master_timeout Timeout for connection to master
        # @raise [Elasticsearch::Transport::Transport::Errors::BadRequest, Elasticsearch::Transport::Transport::Errors::NotFound]
        #   in case of failure
        # @return [Hash] the elasticsearch response
        #
        # @see http://www.elasticsearch.org/guide/reference/api/admin-indices-put-mapping/
        def update_mapping!(suffix: index_version, **options)
          client.indices.put_mapping(options.merge(index: index_name(suffix: suffix), body: mappings_hash.fetch(Esse::MAPPING_ROOT_KEY)))
        end

        # Create or update a mapping
        #
        # @option options [String] :type The name of the document type. This field is required for some elasticsearch versions
        # @option options [Boolean] :ignore_conflicts Specify whether to ignore conflicts while updating the mapping
        #   (default: false)
        # @option options [Boolean] :allow_no_indices Whether to ignore if a wildcard indices expression resolves into
        #   no concrete indices. (This includes `_all` string or when no indices have been specified)
        # @option options [String] :expand_wildcards Whether to expand wildcard expression to concrete indices that
        #   are open, closed or both. (options: open, closed)
        # @option options [String] :ignore_indices When performed on multiple indices, allows to ignore
        #   `missing` ones (options: none, missing) @until 1.0
        # @option options [Boolean] :ignore_unavailable Whether specified concrete indices should be ignored when
        #   unavailable (missing, closed, etc)
        # @option options [Boolean] :update_all_types Whether to update the mapping for all fields
        #   with the same name across all types
        # @option options [Time] :timeout Explicit operation timeout
        # @option options [Boolean] :master_timeout Timeout for connection to master
        # @return [Hash] the elasticsearch response, or an hash with 'errors' as true in case of failure
        #
        # @see http://www.elasticsearch.org/guide/reference/api/admin-indices-put-mapping/
        def update_mapping(suffix: index_version, **options)
          update_mapping!(suffix: suffix, **options)
        rescue Elasticsearch::Transport::Transport::ServerError
          { 'errors' => true }
        end

        # Closes the index for read/write operations, updates the index settings, and open it again
        #
        # @option options [String] :expand_wildcards Whether to expand wildcard expression to concrete indices that
        #   are open, closed or both. (options: open, closed)
        # @option options [String] :ignore_indices When performed on multiple indices, allows to ignore
        #   `missing` ones (options: none, missing) @until 1.0
        # @option options [Boolean] :ignore_unavailable Whether specified concrete indices should be ignored when
        #   unavailable (missing, closed, etc)
        # @option options [Boolean] :include_defaults Whether to return all default clusters setting
        # @option options [Boolean] :preserve_existing Whether to update existing settings.
        #   If set to `true` existing settings on an index remain unchanged, the default is `false`
        # @option options [Time] :master_timeout Specify timeout for connection to master
        # @option options [Boolean] :flat_settings Return settings in flat format (default: false)
        # @raise [Elasticsearch::Transport::Transport::Errors::BadRequest, Elasticsearch::Transport::Transport::Errors::NotFound]
        #   in case of failure
        # @return [Hash] the elasticsearch response
        #
        # @see http://www.elasticsearch.org/guide/reference/api/admin-indices-update-settings/
        def update_settings!(suffix: index_version, **options)
          response = nil

          close!(suffix: suffix)
          begin
            body = settings_hash(cluster_settings: false).fetch(Esse::SETTING_ROOT_KEY)
            response = client.indices.put_settings(options.merge(index: index_name(suffix: suffix), body: body))
          ensure
            open!(suffix: suffix)
          end

          response
        end

        # Closes the index for read/write operations, updates the index settings, and open it again
        #
        # @option options [String] :expand_wildcards Whether to expand wildcard expression to concrete indices that
        #   are open, closed or both. (options: open, closed)
        # @option options [String] :ignore_indices When performed on multiple indices, allows to ignore
        #   `missing` ones (options: none, missing) @until 1.0
        # @option options [Boolean] :ignore_unavailable Whether specified concrete indices should be ignored when
        #   unavailable (missing, closed, etc)
        # @option options [Boolean] :include_defaults Whether to return all default clusters setting
        # @option options [Boolean] :preserve_existing Whether to update existing settings.
        #   If set to `true` existing settings on an index remain unchanged, the default is `false`
        # @option options [Time] :master_timeout Specify timeout for connection to master
        # @option options [Boolean] :flat_settings Return settings in flat format (default: false)
        # @return [Hash] the elasticsearch response, or an hash with 'errors' as true in case of failure
        #
        # @see http://www.elasticsearch.org/guide/reference/api/admin-indices-update-settings/
        def update_settings(suffix: index_version, **options)
          update_settings!(suffix: suffix, **options)
        rescue Elasticsearch::Transport::Transport::ServerError
          { 'errors' => true }
        end
      end

      include InstanceMethods
    end
  end
end
