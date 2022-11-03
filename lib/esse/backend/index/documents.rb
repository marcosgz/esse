# frozen_string_literal: true

module Esse
  module Backend
    class Index
      module InstanceMethods
        # Resolve collection and index data
        #
        # @param types [Array<String>] List of document types. Defaults to all types.
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @option [String, nil] :suffix The index suffix. Defaults to the nil.
        # @option [Hash] :context The collection context. This value will be passed as argument to the collection
        #   May be SQL condition or any other filter you have defined on the collection.
        # @return [Numeric] The number of documents imported
        def import(*types, context: {}, suffix: nil, **options)
          types = repo_hash.keys if types.empty?
          count = 0
          types.each do |type|
            each_serialized_batch(type, **(context || {})) do |batch|
              bulk(type: type, index: batch, suffix: suffix, **options)
              count += batch.size
            end
          end
          count
        end
        alias_method :import!, :import

        # Performs multiple indexing or delete operations in a single API call.
        # This reduces overhead and can greatly increase indexing speed.
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @option [String, nil] :suffix The index suffix. Defaults to the nil.
        # @option [Array] :index list of serialized documents to be indexed(Optional)
        # @option [Array] :delete list of serialized documents to be deleted(Optional)
        # @option [Array] :create list of serialized documents to be created(Optional)
        # @option [String, NilClass] :type The type of the document (Optional for elasticsearch >= 7)
        # @return [Hash, nil] the elasticsearch response or nil if there is no data.
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/docs-bulk.html
        # @see https://github.com/elastic/elasticsearch-ruby/blob/main/elasticsearch-api/lib/elasticsearch/api/utils.rb
        # @see https://github.com/elastic/elasticsearch-ruby/blob/main/elasticsearch-api/lib/elasticsearch/api/actions/bulk.rb
        def bulk(index: nil, delete: nil, create: nil, type: nil, suffix: nil, **options)
          definition = {
            index: index_name(suffix: suffix),
          }.merge(options)
          definition[:type] = type if document_type?

          Esse::Import::Bulk.new(
            index: index,
            delete: delete,
            create: create,
          ).each_request do |request_body|
            Esse::Events.instrument('elasticsearch.bulk') do |payload|
              payload[:request] = definition.merge(body_stats: request_body.stats)
              payload[:response] = resp = coerce_exception { client.bulk(**definition, body: request_body.body) }
              # @todo move it to a BulkRequest class
              if resp&.[]('errors')
                payload[:error] = resp['errors']
                raise resp&.fetch('items', [])&.select { |item| item.values.first['error'] }.join("\n")
              end
              if bulk_wait_interval > 0
                payload[:wait_interval] = bulk_wait_interval
                sleep(bulk_wait_interval)
              else
                payload[:wait_interval] = 0.0
              end
              resp
            end
          end
        end
        alias_method :bulk!, :bulk

        # Adds a JSON document to the specified index and makes it searchable. If the document
        # already exists, updates the document and increments its version.
        #
        #   UsersIndex::User.index(id: 1, body: { name: 'name' }) # { '_id' => 1, ...}
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @option [String, Integer] :id The `_id` of the elasticsearch document
        # @option [Hash] :body The JSON document that will be indexed (Required)
        # @option [String, NilClass] :type The type of the document (Optional for elasticsearch >= 7)
        # @option [String, nil] :suffix The index suffix. Defaults to the nil.
        # @return [Hash] the elasticsearch response Hash
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/docs-index_.html
        # @todo update to allow serialized document as parameter
        def index(id:, body:, type: nil, suffix: nil, **options)
          params = {
            index: index_name(suffix: suffix),
            id: id,
            body: body,
          }
          params[:type] = type if document_type?
          coerce_exception { client.index(**options, **params) }
        end
        alias_method :index!, :index

        # Updates a document using the specified script.
        #
        #   UsersIndex::User.update!(id: 1, body: { doc: { ... } }) # { '_id' => 1, ...}
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @option [String, Integer] :id The `_id` of the elasticsearch document
        # @option [Hash] :body the body of the request
        # @option [String, NilClass] :type The type of the document (Optional for elasticsearch >= 7)
        # @option [String, nil] :suffix The index suffix. Defaults to the nil.
        # @raise [Esse::Transport::NotFoundError] when the doc does not exist
        # @return [Hash] elasticsearch response hash
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/docs-update.html
        # @todo update to allow serialized document as parameter
        def update!(id:, body:, type: nil, suffix: nil, **options)
          params = {
            index: index_name(suffix: suffix),
            id: id,
            body: body,
          }
          params[:type] = type if document_type?
          coerce_exception { client.update(**options, **params) }
        end

        # Updates a document using the specified script.
        #
        #   UsersIndex::User.update(id: 1, body: { doc: { ... } }) # { '_id' => 1, ...}
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @option [String, Integer] :id The `_id` of the elasticsearch document
        # @option [String, NilClass] :type The type of the document (Optional for elasticsearch >= 7)
        # @option [Hash] :body the body of the request
        # @option [String, nil] :suffix The index suffix. Defaults to the nil.
        # @return [Hash] the elasticsearch response, or an hash with 'errors' as true in case of failure
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/docs-update.html
        # @todo update to allow serialized document as parameter
        def update(id:, body:, suffix: nil, **options)
          update!(id: id, body: body, suffix: suffix, **options)
        rescue Esse::Transport::NotFoundError
          { 'errors' => true }
        end

        # Removes a JSON document from the specified index.
        #
        #   UsersIndex::User.delete!(id: 1) # true
        #   UsersIndex::User.delete!(id: 'missing') # raise Esse::Transport::NotFoundError
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @option [String, Integer] :id The `_id` of the elasticsearch document
        # @option [String, NilClass] :type The type of the document (Optional for elasticsearch >= 7)
        # @option [String, nil] :suffix The index suffix. Defaults to the nil.
        # @raise [Esse::transport::NotFoundError] when the doc does not exist
        # @return [Boolean] true when the operation is successfully completed
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/docs-delete.html
        # @todo update to allow serialized document as parameter
        def delete!(id:, type: nil, suffix: nil, **options)
          params = {
            index: index_name(suffix: suffix),
            id: id,
          }
          params[:type] = type if document_type?
          coerce_exception { client.delete(**options, **params) }
        end

        # Removes a JSON document from the specified index.
        #
        #   UsersIndex::User.delete(id: 1) # true
        #   UsersIndex::User.delete(id: 'missing') # false
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @option [String, Integer] :id The `_id` of the elasticsearch document
        # @option [String, NilClass] :type The type of the document (Optional for elasticsearch >= 7)
        # @option [String, nil] :suffix The index suffix. Defaults to the nil.
        # @raise [Esse::Transport::NotFoundError] when the doc does not exist
        # @return [Boolean] true when the operation is successfully completed
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/docs-delete.html
        # @todo update to allow serialized document as parameter
        def delete(id:, type: nil, suffix: nil, **options)
          delete!(id: id, type: type, suffix: suffix, **options)
        rescue Esse::Transport::NotFoundError
          false
        end

        # Gets the number of matches for a search query.
        #
        #   UsersIndex::User.count # 999
        #   UsersIndex::User.count(body: { ... }) # 32
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @option [Hash] :body A query to restrict the results specified with the Query DSL (optional)
        # @option [String, NilClass] :type The type of the document (Optional for elasticsearch >= 7)
        # @option [String, nil] :suffix The index suffix. Defaults to the nil.
        # @return [Integer] amount of documents found
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/search-count.html
        def count(type: nil, suffix: nil, **options)
          params = {
            index: index_name(suffix: suffix),
          }
          params[:type] = type if document_type?
          response = coerce_exception { client.count(**options, **params) }
          response['count']
        rescue Esse::Transport::NotFoundError
          0
        end

        # Check if a JSON document exists
        #
        #   UsersIndex::User.exist?(id: 1) # true
        #   UsersIndex::User.exist?(id: 'missing') # false
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @option [String, Integer] :id The `_id` of the elasticsearch document
        # @option [String, NilClass] :type The type of the document (Optional for elasticsearch >= 7)
        # @option [String, nil] :suffix The index suffix. Defaults to the nil.
        # @return [Boolean] true if the document exists
        def exist?(id:, type: nil, suffix: nil, **options)
          params = {
            index: index_name(suffix: suffix),
            id: id,
          }
          params[:type] = type if document_type?
          coerce_exception { client.exists(**options, **params) }
        end

        # Retrieves the specified JSON document from an index.
        #
        #   UsersIndex::User.find!(id: 1) # { '_id' => 1, ... }
        #   UsersIndex::User.find!(id: 'missing') # raise Esse::Transport::NotFoundError
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @option [String, Integer] :id The `_id` of the elasticsearch document
        # @option [String, NilClass] :type The type of the document (Optional for elasticsearch >= 7)
        # @option [String, nil] :suffix The index suffix. Defaults to the nil.
        # @raise [Esse::Transport::NotFoundError] when the doc does not exist
        # @return [Hash] The elasticsearch document.
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/docs-get.html
        def find!(id:, type: nil, suffix: nil, **options)
          params = {
            index: index_name(suffix: suffix),
            id: id,
          }
          params[:type] = type if document_type?
          coerce_exception { client.get(**options, **params) }
        end

        # Retrieves the specified JSON document from an index.
        #
        #   UsersIndex::User.find(id: 1) # { '_id' => 1, ... }
        #   UsersIndex::User.find(id: 'missing') # nil
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @option [String, Integer] :id The `_id` of the elasticsearch document
        # @option [String, NilClass] :type The type of the document (Optional for elasticsearch >= 7)
        # @option [String, nil] :suffix The index suffix. Defaults to the nil.
        # @return [Hash, nil] The elasticsearch document
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/docs-get.html
        def find(id:, suffix: nil, **options)
          find!(id: id, suffix: suffix, **options)
        rescue Esse::Transport::NotFoundError
          nil
        end
      end

      include InstanceMethods
    end
  end
end
