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
        # @return [Hash] the elasticsearch response, or an hash with 'errors' as true in case of failure
        #
        # @see http://www.elasticsearch.org/blog/changing-mapping-with-zero-downtime/
        def create_index(suffix: index_version, **options)
          create_index!(suffix: suffix, **options)
        rescue Elasticsearch::Transport::Transport::Errors::BadRequest
          { 'errors' => true }
        end

        # Creates index and applies mappings and settings.
        #
        #   UsersIndex.elasticsearch.create_index! # creates index named `<prefix_>users_<suffix|index_version|timestamp>`
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
        # @raise [Elasticsearch::Transport::Transport::Errors::NotFound] when index already exists
        # @return [Hash] the elasticsearch response
        #
        # @see http://www.elasticsearch.org/blog/changing-mapping-with-zero-downtime/
        def create_index!(suffix: index_version, **options)
          options = DEFAULT_OPTIONS.merge(options)
          name = build_real_index_name(suffix)
          definition = [settings_hash, mappings_hash].reduce(&:merge)

          if options.delete(:alias) && name != index_name
            definition[:aliases] = { index_name => {} }
          end

          Esse::Events.instrument('elasticsearch.create_index') do |payload|
            payload[:request] = opts = options.merge(index: name, body: definition)
            payload[:response] = response = client.indices.create(**opts)
            cluster.wait_for_status! if response
            response
          end
        end
      end

      include InstanceMethods
    end
  end
end
