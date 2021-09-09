# frozen_string_literal: true

module Esse
  module Backend
    class Index
      module InstanceMethods
        # Deletes ES index
        #
        #   UsersIndex.elasticsearch.delete_index! # deletes `<prefix_>users<_suffix|_index_version|_timestamp>` index
        #
        # @param suffix [String, nil] The index suffix Use nil if you want to delete the current index.
        # @raise [Elasticsearch::Transport::Transport::Errors::NotFound] when index does not exists
        # @return [Hash] elasticsearch response
        def delete_index!(suffix: index_version)
          client.indices.delete(index: index_name(suffix: suffix)).tap do |result|
            cluster.wait_for_status! if result
          end
        end

        # Deletes ES index
        #
        #   UsersIndex.elasticsearch.delete_index # deletes `<prefix_>users<_suffix|_index_version|_timestamp>` index
        #
        # @param suffix [String, nil] The index suffix Use nil if you want to delete the current index.
        # @return [Hash] the elasticsearch response, or an hash with 'errors' as true in case of failure
        def delete_index(suffix: index_version)
          delete_index!(suffix: suffix)
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          { 'errors' => true }
        end
      end

      include InstanceMethods
    end
  end
end
