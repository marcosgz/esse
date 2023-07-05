# frozen_string_literal: true

module Esse
  module Backend
    class Index
      module InstanceMethods
        # Return a list of index aliases.
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @param options [Array] :index list of serialized documents to be indexed(Optional)
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/indices-aliases.html
        def aliases(**options)
          response = coerce_exception { client.indices.get_alias({ index: index_name, name: '*' }.merge(options)) }
          idx_name = response.keys.find { |idx| idx.start_with?(index_name) }
          return [] unless idx_name

          response.dig(idx_name, 'aliases')&.keys || []
        rescue Esse::Transport::NotFoundError
          []
        end

        # Returns a list of indices.
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @return [Array] list of indices that match with `index_name`.
        def indices(**options)
          coerce_exception { client.indices.get_alias({ name: index_name }.merge(options)).keys }
        rescue Esse::Transport::NotFoundError
          []
        end

        # Replaces all existing aliases by the respective suffixed index from argument.
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @option [String] :suffix The suffix of the index used for versioning.
        # @raise [Esse::Transport::NotFoundError] in case of failure
        # @return [Hash] the elasticsearch response
        def update_aliases!(suffix:, **options)
          raise(ArgumentError, 'index suffix cannot be nil') if suffix.nil?

          options[:body] = {
            actions: [
              *indices.map do |index|
                { remove: { index: index, alias: index_name } }
              end,
              { add: {index: build_real_index_name(suffix), alias: index_name } }
            ],
          }

          Esse::Events.instrument('elasticsearch.update_aliases') do |payload|
            payload[:request] = options
            payload[:response] = coerce_exception { client.indices.update_aliases(options)}
          end
        end

        # Replaces all existing aliases by the respective suffixed index from argument.
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @option [String] :suffix The suffix of the index used for versioning.
        # @raise [Esse::Backend::NotFoundError] in case of failure
        # @return [Hash] the elasticsearch response, or an hash with 'errors' as true in case of failure
        def update_aliases(suffix:, **options)
          update_aliases!(suffix: suffix, **options)
        rescue Esse::Transport::NotFoundError
          { 'errors' => true }
        end
      end

      include InstanceMethods
    end
  end
end
