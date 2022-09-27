# frozen_string_literal: true

module Esse
  class Index
    module ClassMethods
      # Get the aliases for the index.
      def aliases(**options)
        response = cluster.api.aliases(**options, index: index_name, name: '*')
        idx_name = response.keys.find { |idx| idx.start_with?(index_name) }
        return [] unless idx_name

        response.dig(idx_name, 'aliases')&.keys || []
      rescue Esse::Transport::NotFoundError
        []
      end

      # Return list of real index names for the virtual index name(alias)
      def indices_pointing_to_alias(**options)
        cluster.api.aliases(**options, name: index_name).keys
      rescue Esse::Transport::NotFoundError
        []
      end
    end

    extend ClassMethods
  end
end
