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
        # @raise [Esse::Backend::ServerError]
        #   in case of failure
        # @return [Hash] the elasticsearch response
        #
        # @see http://www.elasticsearch.org/guide/reference/api/admin-indices-put-mapping/
        def update_mapping!(suffix: index_version, **options)
          Esse::Events.instrument('elasticsearch.update_mapping') do |payload|
            body = mappings_hash.fetch(Esse::MAPPING_ROOT_KEY)
            if (type = options[:type])
              body = body[type.to_s] || body[type.to_sym]
            end
            payload[:request] = opts = options.merge(index: index_name(suffix: suffix), body: body)
            payload[:response] = coerce_exception { client.indices.put_mapping(**opts) }
          end
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
        rescue ServerError
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
        # @raise [Esse::Backend::ServerError]
        #   in case of failure
        # @return [Hash] the elasticsearch response
        #
        # @see http://www.elasticsearch.org/guide/reference/api/admin-indices-update-settings/
        def update_settings!(suffix: index_version, **options)
          response = nil

          settings = settings_hash.fetch(Esse::SETTING_ROOT_KEY).transform_keys(&:to_s)
          settings.delete('number_of_shards') # Can't change number of shards for an index
          analysis = settings.delete('analysis')

          if settings.any?
            # When changing the number of replicas the index needs to be open. Changing the number of replicas on a
            # closed index might prevent the index to be opened correctly again.
            Esse::Events.instrument('elasticsearch.update_settings') do |payload|
              payload[:request] = opts = options.merge(index: index_name(suffix: suffix), body: { index: settings })
              payload[:response] = response = coerce_exception { client.indices.put_settings(**opts) }
            end
          end

          if analysis
            # It is also possible to define new analyzers for the index. But it is required to close the
            # index first and open it after the changes are made.
            close!(suffix: suffix)
            begin
              Esse::Events.instrument('elasticsearch.update_settings') do |payload|
                payload[:request] = opts = options.merge(index: index_name(suffix: suffix), body: { analysis: analysis })
                payload[:response] = response = coerce_exception { client.indices.put_settings(**opts) }
              end
            ensure
              open!(suffix: suffix)
            end
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
        rescue ServerError
          { 'errors' => true }
        end
      end

      include InstanceMethods
    end
  end
end
