# frozen_string_literal: true

module Esse
  class Index
    module ClassMethods
      CREATE_INDEX_RESERVED_KEYWORDS = {
        alias: true,
      }.freeze

      # Creates index and applies mappings and settings.
      #
      #   UsersIndex.create_index # creates index named `<prefix_>users_<suffix|index_version|timestamp>`
      #
      # @param options [Hash] Options hash
      # @option options [Boolean] :alias Update `index_name` alias along with the new index
      # @option options [String] :suffix The index suffix. Defaults to the `IndexClass#index_version` or
      #   `Esse.timestamp`. Suffixed index names might be used for zero-downtime mapping change.
      # @option arguments [String] :wait_for_active_shards Set the number of active shards
      #    to wait for before the operation returns.
      # @option arguments [Time] :timeout Explicit operation timeout
      # @option arguments [Time] :master_timeout Specify timeout for connection to master
      # @option arguments [Hash] :headers Custom HTTP headers
      # @option arguments [Hash] :body The configuration for the index (`settings` and `mappings`)
      # @raise [Esse::Transport::NotFoundError] when index already exists
      # @return [Hash] the elasticsearch response
      #
      # @see http://www.elasticsearch.org/blog/changing-mapping-with-zero-downtime/
      # @see Esse::ClientProxy#create_index
      def create_index(suffix: index_version, **options)
        options = CREATE_INDEX_RESERVED_KEYWORDS.merge(options)
        name = build_real_index_name(suffix)
        definition = [settings_hash, mappings_hash].reduce(&:merge)

        if options.delete(:alias) && name != index_name
          definition[:aliases] = { index_name => {} }
        end

        cluster.api.create_index(index: name, body: definition, **options)
      end

      # Open a previously closed index
      #
      # @option options [String, nil] :suffix The index suffix
      # @see Esse::ClientProxy#open
      def open(suffix: nil, **options)
        cluster.api.open(index: index_name(suffix: suffix), **options)
      end

      # Close an index (keep the data on disk, but deny operations with the index).
      #
      # @option options [String, nil] :suffix The index suffix
      # @see Esse::ClientProxy#close
      def close(suffix: nil, **options)
        cluster.api.close(index: index_name(suffix: suffix), **options)
      end
    end

    extend ClassMethods
  end
end
