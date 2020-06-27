# frozen_string_literal: true

module Esse
  module Backend
    class Index
      module InstanceMethods
        # Deletes, creates and imports data to the index. Performs zero-downtime index resetting.
        #
        # @option options [String, nil] :suffix The index suffix. Defaults to the index_version.
        #   A uniq index name will be generated if one index already exist with the given alias.
        # @option options [Time] :timeout Explicit operation timeout
        # @raise [Elasticsearch::Transport::Transport::Errors::BadRequest, Elasticsearch::Transport::Transport::Errors::NotFound]
        #   in case of failure
        # @return [Hash] the elasticsearch response
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/master/indices-open-close.html
        def reset_index!(suffix: index_version, **options)
          existing = []
          suffix ||= Esse.timestamp
          while exist?(suffix: suffix).tap { |exist| existing << suffix if exist }
            suffix = Esse.timestamp
          end

          create_index!(suffix: suffix, **options)
          import!(suffix: suffix, **options)
          update_aliases!(suffix: suffix)
          existing.each { |s| delete_index!(suffix: suffix, **options) }
          true
        end
      end

      include InstanceMethods
    end
  end
end
