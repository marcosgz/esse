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
        # @raise [Elasticsearch::Transport::Transport::Errors::BadRequest, Elasticsearch::Transport::Transport::Errors::NotFound]
        #   in case of failure
        # @return [Hash] the elasticsearch response
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/master/indices-refresh.html
        def refresh!(suffix: index_version, **options)
          client.indices.refresh(
            options.merge(index: index_name(suffix: suffix)),
          )
        end

        # Performs the refresh operation in one or more indices.
        #
        # @note The refresh operation can adversely affect indexing throughput when used too frequently.
        # @param :suffix [String, nil] :suffix The index suffix. Defaults to the index_version.
        #   A uniq index name will be generated if one index already exist with the given alias.
        # @param options [Hash] Options hash
        # @return [Hash, false] the elasticsearch response, or false in case of failure
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/master/indices-refresh.html
        def refresh(suffix: index_version, **options)
          refresh!(suffix: suffix, **options)
        rescue Elasticsearch::Transport::Transport::ServerError
          false
        end
      end

      include InstanceMethods
    end
  end
end
