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
        # @raise [Esse::Backend::ServerError]
        #   in case of failure
        # @return [Hash] the elasticsearch response
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/master/indices-open-close.html
        def reset_index!(suffix: index_version, import: true, **options)
          existing = []
          suffix ||= Esse.timestamp
          suffix = Esse.timestamp while index_exist?(suffix: suffix).tap { |exist| existing << suffix if exist }

          create_index!(**options, suffix: suffix, alias: false)
          import!(**options, suffix: suffix) if import
          update_aliases!(suffix: suffix)
          existing.each { |_s| delete_index!(**options, suffix: suffix) }
          true
        end
      end

      include InstanceMethods
    end
  end
end
