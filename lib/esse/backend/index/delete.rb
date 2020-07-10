# frozen_string_literal: true

module Esse
  module Backend
    class Index
      module InstanceMethods
        # Deletes ES index
        #
        #   UsersIndex.backend.delete_index! # deletes `<prefix_>users<_suffix|_index_version|_timestamp>` index
        #
        # @param suffix [String, nil] The index suffix Use nil if you want to delete the current index.
        # @raise [Elasticsearch::Transport::Transport::Errors::NotFound] when index does not exists
        # @return [Hash] elasticsearch response
        def delete_index!(suffix:)
          client.indices.delete(index: index_name(suffix: suffix))
        end

        # Deletes ES index
        #
        #   UsersIndex.backend.delete_index # deletes `<prefix_>users<_suffix|_index_version|_timestamp>` index
        #
        # @param suffix [String, nil] The index suffix Use nil if you want to delete the current index.
        # @return [Hash, false] elasticsearch response, of false in case of error.
        def delete_index(suffix: index_version)
          delete_index!(suffix: suffix)
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          false
        end
      end

      include InstanceMethods
    end
  end
end
