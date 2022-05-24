# frozen_string_literal: true

module Esse
  module Backend
    class Index
      module InstanceMethods
        # Performs the refresh operation in one or more indices.
        #
        # @note The refresh operation can adversely affect indexing throughput when used too frequently.
        # @param :suffix [String, nil] :suffix The index suffix. Defaults to the index_version.
        #   A uniq index name will be generated if one index already exist with the given alias.
        # @param options [Hash] Options hash
        # @raise [Esse::Backend::ServerError]
        #   in case of failure
        # @return [Hash] the elasticsearch response
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/master/indices-refresh.html
        def refresh!(suffix: index_version, **options)
          coerce_exception do
            client.indices.refresh(
              options.merge(index: index_name(suffix: suffix)),
            )
          end
        end

        # Performs the refresh operation in one or more indices.
        #
        # @note The refresh operation can adversely affect indexing throughput when used too frequently.
        # @param :suffix [String, nil] :suffix The index suffix. Defaults to the index_version.
        #   A uniq index name will be generated if one index already exist with the given alias.
        # @param options [Hash] Options hash
        # @return [Hash] the elasticsearch response, or an hash with 'errors' as true in case of failure
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/master/indices-refresh.html
        def refresh(suffix: index_version, **options)
          refresh!(suffix: suffix, **options)
        rescue ServerError
          { 'errors' => true }
        end
      end

      include InstanceMethods
    end
  end
end
