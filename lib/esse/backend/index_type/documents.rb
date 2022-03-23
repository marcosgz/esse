# frozen_string_literal: true

module Esse
  module Backend
    class IndexType
      module InstanceMethods
        # Resolve collection and index data
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @option [String, nil] :suffix The index suffix. Defaults to the nil.
        # @option [Hash] :context The collection context. This value will be passed as argument to the collection
        #   May be SQL condition or any other filter you have defined on the collection.
        def import(context: {}, suffix: nil, **options)
          each_serialized_batch(**(context || {})) do |batch|
            bulk(index: batch, suffix: suffix, **options)
          end
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
        # @return [Hash, nil] the elasticsearch response or nil if there is no data.
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/docs-bulk.html
        def bulk(index: nil, delete: nil, create: nil, suffix: nil, **options)
          body = []
          Array(index).each do |entry|
            id, data = Esse.doc_id!(entry)
            body << { index: { _id: id, data: data } } if id
          end
          Array(create).each do |entry|
            id, data = Esse.doc_id!(entry)
            body << { create: { _id: id, data: data } } if id
          end
          Array(delete).each do |entry|
            id, _data = Esse.doc_id!(entry, delete: [], keep: %w[_id id])
            body << { delete: { _id: id } } if id
          end

          return if body.empty?

          definition = {
            index: index_name(suffix: suffix),
            type: type_name,
            body: body,
          }.merge(options)

          client.bulk(definition).tap do
            sleep(bulk_wait_interval) if bulk_wait_interval > 0
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
        # @option [String, nil] :suffix The index suffix. Defaults to the nil.
        # @return [Hash] the elasticsearch response Hash
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/docs-index_.html
        def index(id:, body:, suffix: nil, **options)
          client.index(
            index: index_name(suffix: suffix), type: type_name, id: id, body: body, **options
          )
        end
        alias_method :index!, :index

        # Updates a document using the specified script.
        #
        #   UsersIndex::User.update!(id: 1, body: { doc: { ... } }) # { '_id' => 1, ...}
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @option [String, Integer] :id The `_id` of the elasticsearch document
        # @option [Hash] :body the body of the request
        # @option [String, nil] :suffix The index suffix. Defaults to the nil.
        # @raise [Elasticsearch::Transport::Transport::Errors::NotFound] when the doc does not exist
        # @return [Hash] elasticsearch response hash
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/docs-update.html
        def update!(id:, body:, suffix: nil, **options)
          client.update(
            index: index_name(suffix: suffix), type: type_name, id: id, body: body, **options
          )
        end

        # Updates a document using the specified script.
        #
        #   UsersIndex::User.update(id: 1, body: { doc: { ... } }) # { '_id' => 1, ...}
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @option [String, Integer] :id The `_id` of the elasticsearch document
        # @option [Hash] :body the body of the request
        # @option [String, nil] :suffix The index suffix. Defaults to the nil.
        # @return [Hash] the elasticsearch response, or an hash with 'errors' as true in case of failure
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/docs-update.html
        def update(id:, body:, suffix: nil, **options)
          update!(id: id, body: body, suffix: suffix, **options)
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          { 'errors' => true }
        end

        # Removes a JSON document from the specified index.
        #
        #   UsersIndex::User.delete!(id: 1) # true
        #   UsersIndex::User.delete!(id: 'missing') # raise Elasticsearch::Transport::Transport::Errors::NotFound
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @option [String, Integer] :id The `_id` of the elasticsearch document
        # @option [String, nil] :suffix The index suffix. Defaults to the nil.
        # @raise [Elasticsearch::Transport::Transport::Errors::NotFound] when the doc does not exist
        # @return [Boolean] true when the operation is successfully completed
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/docs-delete.html
        def delete!(id:, suffix: nil, **options)
          client.delete(options.merge(index: index_name(suffix: suffix), type: type_name, id: id))
        end

        # Removes a JSON document from the specified index.
        #
        #   UsersIndex::User.delete(id: 1) # true
        #   UsersIndex::User.delete(id: 'missing') # false
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @option [String, Integer] :id The `_id` of the elasticsearch document
        # @option [String, nil] :suffix The index suffix. Defaults to the nil.
        # @raise [Elasticsearch::Transport::Transport::Errors::NotFound] when the doc does not exist
        # @return [Boolean] true when the operation is successfully completed
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/docs-delete.html
        def delete(id:, suffix: nil, **options)
          delete!(id: id, suffix: suffix, **options)
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          false
        end

        # Gets the number of matches for a search query.
        #
        #   UsersIndex::User.count # 999
        #   UsersIndex::User.count(body: { ... }) # 32
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @option [Hash] :body A query to restrict the results specified with the Query DSL (optional)
        # @option [String, nil] :suffix The index suffix. Defaults to the nil.
        # @return [Integer] amount of documents found
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/search-count.html
        def count(suffix: nil, **options)
          response = client.count(options.merge(index: index_name(suffix: suffix), type: type_name))
          response['count']
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          0
        end

        # Check if a JSON document exists
        #
        #   UsersIndex::User.exist?(id: 1) # true
        #   UsersIndex::User.exist?(id: 'missing') # false
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @option [String, Integer] :id The `_id` of the elasticsearch document
        # @option [String, nil] :suffix The index suffix. Defaults to the nil.
        # @return [Boolean] true if the document exists
        def exist?(id:, suffix: nil, **options)
          client.exists(options.merge(index: index_name(suffix: suffix), type: type_name, id: id))
        end

        # Retrieves the specified JSON document from an index.
        #
        #   UsersIndex::User.find!(id: 1) # { '_id' => 1, ... }
        #   UsersIndex::User.find!(id: 'missing') # raise Elasticsearch::Transport::Transport::Errors::NotFound
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @option [String, Integer] :id The `_id` of the elasticsearch document
        # @option [String, nil] :suffix The index suffix. Defaults to the nil.
        # @raise [Elasticsearch::Transport::Transport::Errors::NotFound] when the doc does not exist
        # @return [Hash] The elasticsearch document.
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/docs-get.html
        def find!(id:, suffix: nil, **options)
          client.get(options.merge(index: index_name(suffix: suffix), type: type_name, id: id))
        end

        # Retrieves the specified JSON document from an index.
        #
        #   UsersIndex::User.find(id: 1) # { '_id' => 1, ... }
        #   UsersIndex::User.find(id: 'missing') # nil
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @option [String, Integer] :id The `_id` of the elasticsearch document
        # @option [String, nil] :suffix The index suffix. Defaults to the nil.
        # @return [Hash, nil] The elasticsearch document
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/docs-get.html
        def find(id:, suffix: nil, **options)
          find!(id: id, suffix: suffix, **options)
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          nil
        end
      end

      include InstanceMethods
    end
  end
end
