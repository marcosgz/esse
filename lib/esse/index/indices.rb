# frozen_string_literal: true

module Esse
  class Index
    module ClassMethods
      CREATE_INDEX_RESERVED_KEYWORDS = {
        alias: true,
      }.freeze

      # Creates index and applies mappings and settings.
      #
      #   UsersIndex.create_index # creates index named `<cluster.index_prefix>users<index_suffix>`
      #
      # @param options [Hash] Options hash
      # @option options [Boolean] :alias Update `index_name` alias along with the new index
      # @option options [String] :suffix The index suffix. Defaults to the `IndexClass#index_suffix` or
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
      # @see Esse::Transport#create_index
      def create_index(suffix: nil, body: nil, settings: nil, **options)
        options = CREATE_INDEX_RESERVED_KEYWORDS.merge(options)
        name = build_real_index_name(suffix)
        definition = body || [settings_hash(settings: settings), mappings_hash].reduce(&:merge)

        if options.delete(:alias) && name != index_name
          definition[:aliases] = { index_name => {} }
        end

        cluster.api.create_index(index: name, body: definition, **options)
      end

      # Deletes, creates and imports data to the index. Performs zero-downtime index resetting.
      #
      # @option options [String, nil] :suffix The index suffix. Defaults to the index_suffix.
      #   A uniq index name will be generated if one index already exist with the given alias.
      # @option options [Time] :timeout Explicit operation timeout
      # @raise [Esse::Transport::ServerError]
      #   in case of failure
      # @return [Hash] the elasticsearch response
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/master/indices-open-close.html
      def reset_index(suffix: index_suffix, settings: nil, optimize: true, import: true, reindex: false, refresh: nil, **options)
        cluster.throw_error_when_readonly!

        suffix ||= Esse.timestamp
        suffix = Esse.timestamp while index_exist?(suffix: suffix)
        syncronous_import = true
        syncronous_import = false if reindex.is_a?(Hash) && reindex[:wait_for_completion] == false

        optimized_creation = optimize && syncronous_import && (import || reindex)
        if optimized_creation
          definition = [settings_hash(settings: settings), mappings_hash].reduce(&:merge)
          number_of_replicas = definition.dig(Esse::SETTING_ROOT_KEY, :index, :number_of_replicas) || 1
          refresh_interval = definition.dig(Esse::SETTING_ROOT_KEY, :index, :refresh_interval) || '1s'
          new_number_of_replicas = ((definition[Esse::SETTING_ROOT_KEY] ||= {})[:index] ||= {})[:number_of_replicas] = 0
          new_refresh_interval = ((definition[Esse::SETTING_ROOT_KEY] ||= {})[:index] ||= {})[:refresh_interval] = '-1'
          create_index(**options, suffix: suffix, alias: false, body: definition)
        else
          create_index(**options, suffix: suffix, alias: false, settings: settings)
        end

        if index_exist? && aliases.none?
          cluster.api.delete_index(index: index_name)
        end

        if import
          import_kwargs = import.is_a?(Hash) ? import : {}
          import_kwargs[:refresh] ||= refresh unless refresh.nil?
          import(**options, **import_kwargs, suffix: suffix)
        elsif reindex && (source_indexes = indices_pointing_to_alias).any?
          reindex_kwargs = reindex.is_a?(Hash) ? reindex : {}
          reindex_kwargs[:refresh] ||= refresh unless refresh.nil?
          source_indexes.each do |from|
            reindex(**reindex_kwargs, body: {
              source: { index: from },
              dest: { index: index_name(suffix: suffix) }
            })
          end
        end

        if optimized_creation && number_of_replicas != new_number_of_replicas || refresh_interval != new_refresh_interval
          settings ||= {}
          settings[:index] ||= {}
          settings[:index][:number_of_replicas] = number_of_replicas
          settings[:index][:refresh_interval] = refresh_interval
          update_settings(suffix: suffix, settings: settings)
          refresh(suffix: suffix)
        end

        update_aliases(suffix: suffix) if syncronous_import

        true
      end

      # Copies documents from a source to a destination.
      #
      # To avoid http timeout, we are sending the request with `wait_for_completion: false` and polling the task
      # until it is completed.
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html
      def reindex(body:, wait_for_completion: true, scroll: '30m', poll_interval: 5, **options)
        resp = cluster.api.reindex(**options, body: body, scroll: scroll, wait_for_completion: false)
        return resp unless wait_for_completion

        task_id = resp['task']
        task = nil
        begin
          while (task = cluster.api.task(id: task_id))['completed'] == false
            sleep poll_interval.to_i
          end
        rescue Interrupt => e
          cluster.api.cancel_task(id: task_id)
          raise e
        end
        task
      end

      # Checks the index existance. Returns true or false
      #
      #   UsersIndex.index_exist? #=> true
      #
      # @param options [Hash] Options hash
      # @option options [String, nil] :suffix The index suffix
      # @see Esse::Transport#index_exist?
      def index_exist?(suffix: nil)
        cluster.api.index_exist?(index: index_name(suffix: suffix))
      end

      # Deletes an existing index.
      #
      #   UsersIndex.delete_index # deletes `<cluster.index_prefix>users<index_suffix>` index
      #
      # @param suffix [String, nil] The index suffix Use nil if you want to delete the current index.
      # @raise [Esse::Transport::NotFoundError] when index does not exists
      # @return [Hash] elasticsearch response
      def delete_index(suffix: nil, **options)
        index = suffix ? index_name(suffix: suffix) : indices_pointing_to_alias.first
        index ||= index_name
        cluster.api.delete_index(**options, index: index)
      end

      # Open a previously closed index
      #
      # @option options [String, nil] :suffix The index suffix
      # @see Esse::Transport#open
      def open(suffix: nil, **options)
        cluster.api.open(index: index_name(suffix: suffix), **options)
      end

      # Close an index (keep the data on disk, but deny operations with the index).
      #
      # @option options [String, nil] :suffix The index suffix
      # @see Esse::Transport#close
      def close(suffix: nil, **options)
        cluster.api.close(index: index_name(suffix: suffix), **options)
      end

      # Performs the refresh operation in one or more indices.
      #
      # @note The refresh operation can adversely affect indexing throughput when used too frequently.
      # @param :suffix [String, nil] :suffix The index suffix
      # @see Esse::Transport#refresh
      def refresh(suffix: nil, **options)
        cluster.api.refresh(index: index_name(suffix: suffix), **options)
      end

      # Updates index mappings
      #
      # @param :suffix [String, nil] :suffix The index suffix
      # @see Esse::Transport#update_mapping
      def update_mapping(suffix: nil, **options)
        body = mappings_hash.fetch(Esse::MAPPING_ROOT_KEY)
        if (type = options[:type])
          # Elasticsearch <= 5.x should submit request with type both in the path and in the body
          # Elasticsearch 6.x should submit request with type in the path but not in the body
          # Elasticsearch >= 7.x does not support type in the mapping
          body = body[type.to_s] || body[type.to_sym] || body
        end
        cluster.api.update_mapping(index: index_name(suffix: suffix), body: body, **options)
      end

      # Updates index settings
      #
      # @param :suffix [String, nil] :suffix The index suffix
      # @see Esse::Transport#update_settings
      def update_settings(suffix: nil, settings: nil, **options)
        response = nil

        settings = HashUtils.deep_transform_keys(settings_hash(settings: settings).fetch(Esse::SETTING_ROOT_KEY), &:to_sym)
        if options[:body]
          body = HashUtils.deep_transform_keys(options.delete(:body), &:to_sym)
          settings = HashUtils.deep_merge(settings, body)
        end
        settings.delete(:number_of_shards) # Can't change number of shards for an index
        settings[:index]&.delete(:number_of_shards)
        analysis = settings.delete(:analysis)

        if settings.any?
          response = cluster.api.update_settings(index: index_name(suffix: suffix), body: settings, **options)
        end

        if analysis
          # It is also possible to define new analyzers for the index. But it is required to close the
          # index first and open it after the changes are made.
          close(suffix: suffix)
          begin
            response = cluster.api.update_settings(index: index_name(suffix: suffix), body: { analysis: analysis }, **options)
          ensure
            self.open(suffix: suffix)
          end
        end

        response
      end
    end

    extend ClassMethods
  end
end
