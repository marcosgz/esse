# frozen_string_literal: true

module Esse
  module Backend
    class Index
      module InstanceMethods
        DEFAULT_OPTIONS = {
          alias: true,
        }.freeze

        # Creates index and applies mappings and settings.
        #
        #   UsersIndex.elasticsearch.create_index # creates index named `<prefix_>users_<suffix|index_version|timestamp>`
        #
        # @param options [Hash] Options hash
        # @option options [Boolean] :alias Update `index_name` alias along with the new index
        # @option options [String] :suffix The index suffix. Defaults to the `IndexClass#index_version` or
        #   `Esse.timestamp`. Suffixed index names might be used for zero-downtime mapping change.
        # @return [Hash, false] the elasticsearch response or false in case of unsuccessful creation.
        #
        # @see http://www.elasticsearch.org/blog/changing-mapping-with-zero-downtime/
        def create_index(suffix: index_version, **options)
          create_index!(suffix: suffix, **options)
        rescue Elasticsearch::Transport::Transport::Errors::BadRequest
          false
        end

        # Creates index and applies mappings and settings.
        #
        #   UsersIndex.elasticsearch.create_index! # creates index named `<prefix_>users_<suffix|index_version|timestamp>`
        #
        # @param options [Hash] Options hash
        # @option options [Boolean] :alias Update `index_name` alias along with the new index
        # @option options [String] :suffix The index suffix. Defaults to the `IndexClass#index_version` or
        #   `Esse.timestamp`. Suffixed index names might be used for zero-downtime mapping change.
        # @raise [Elasticsearch::Transport::Transport::Errors::NotFound] when index already exists
        # @return [Hash] the elasticsearch response
        #
        # @see http://www.elasticsearch.org/blog/changing-mapping-with-zero-downtime/
        def create_index!(suffix: index_version, **options)
          options = DEFAULT_OPTIONS.merge(options)
          name = build_real_index_name(suffix)
          definition = [settings_hash, mappings_hash].reduce(&:merge)

          if options[:alias] && name != index_name
            definition[:aliases] = { index_name => {} }
          end

          client.indices.create(index: name, body: definition)
        end
      end

      include InstanceMethods
    end
  end
end
