# frozen_string_literal: true

module Esse
  module Backend
    class Index
      module InstanceMethods
        # Deletes ES index
        #
        #   UsersIndex.backend.delete! # deletes `<prefix_>users<_suffix|_index_version|_timestamp>` index
        #
        # @param options [Hash] Options hash
        # @option [String, nil] :suffix The index suffix Use nil if you want to delete the current index.
        # @raise [Elasticsearch::Transport::Transport::Errors::NotFound] when index does not exists
        # @return [Hash] elasticsearch response
        def delete!(suffix:)
          name = suffix ? real_index_name(suffix) : index_name

          client.indices.delete(index: name)
        end

        # Deletes ES index
        #
        #   UsersIndex.backend.delete # deletes `<prefix_>users<_suffix|_index_version|_timestamp>` index
        #
        # @param options [Hash] Options hash
        # @option [String] :suffix The index suffix. Use nil if you want to delete the current index.
        # @return [Hash, false] elasticsearch response, of false in case of error.
        def delete(suffix: index_version)
          delete!(suffix: suffix)
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          false
        end
      end

      include InstanceMethods
    end
  end
end
