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

      # Replaces all existing aliases by the respective suffixed index from argument.
      #
      # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
      # @option [Array<String>] :suffix One or more index suffixes to point the alias to.
      # @raise [Esse::Transport::ServerError] in case of failure
      # @return [Hash] the elasticsearch response
      def update_aliases(suffix:, **options)
        cluster.throw_error_when_readonly!
        raise(ArgumentError, 'index suffix cannot be nil') if suffix.nil?

        options[:body] = {
          actions: [
            *indices_pointing_to_alias.map do |index|
              { remove: { index: index, alias: index_name } }
            end,
            *Array(suffix).map do |value|
              { add: { index: build_real_index_name(value), alias: index_name } }
            end,
          ],
        }
        cluster.api.update_aliases(**options)
      end
    end

    extend ClassMethods
  end
end
