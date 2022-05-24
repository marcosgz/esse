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
        # @raise [Esse::Backend::NotFoundError] when index does not exists
        # @return [Hash] elasticsearch response
        def delete_index!(suffix: index_version, **options)
          Esse::Events.instrument('elasticsearch.delete_index') do |payload|
            payload[:request] = opts = options.merge(index: index_name(suffix: suffix))
            payload[:response] = response = coerce_exception { client.indices.delete(**opts) }
            coerce_exception { cluster.wait_for_status! } if response
            response
          end
        end

        # Deletes ES index
        #
        #   UsersIndex.elasticsearch.delete_index # deletes `<prefix_>users<_suffix|_index_version|_timestamp>` index
        #
        # @param suffix [String, nil] The index suffix Use nil if you want to delete the current index.
        # @return [Hash] the elasticsearch response, or an hash with 'errors' as true in case of failure
        def delete_index(suffix: index_version, **options)
          delete_index!(suffix: suffix, **options)
        rescue ServerError
          { 'errors' => true }
        end
      end

      include InstanceMethods
    end
  end
end
