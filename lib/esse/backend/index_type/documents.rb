# frozen_string_literal: true

module Esse
  module Backend
    class IndexType
      module InstanceMethods
        # Performs multiple indexing or delete operations in a single API call.
        # This reduces overhead and can greatly increase indexing speed.
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @param options [Array] :index list of serialized documents to be indexed(Optional)
        # @param options [Array] :update list of serialized documents to be updated(Optional)
        # @param options [Array] :delete list of serialized documents to be deleted(Optional)
        # @return [Hash, nil] the elasticsearch response or nil if there is no data.
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/docs-bulk.html
        def bulk(index: nil, update: nil, delete: nil, **options)
          body = []
          Array(index).each do |entry|
            id = Esse.doc_id(entry)
            body << { index: { _id: id, data: entry } } if id
          end
          Array(update).each do |entry|
            id = Esse.doc_id(entry)
            body << { update: { _id: id, data: entry } } if id
          end
          Array(delete).each do |entry|
            id = Esse.doc_id(entry)
            body << { delete: { _id: id } } if id
          end

          return if body.empty?

          definition = {
            index: index_name,
            type: type_name,
            body: body,
          }.merge(options)

          client.bulk(definition)
        end

        # Adds a JSON document to the specified index and makes it searchable. If the document
        # already exists, updates the document and increments its version.
        #
        #   UsersIndex::User.create!(id: 1, body: { name: 'name' }) # { '_id' => 1, ...}
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @param options [String, Integer] :id The `_id` of the elasticsearch document
        # @param options [Hash] :body The JSON document that will be indexed (Required)
        # @return [Hash] the elasticsearch response Hash
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/docs-index_.html
        def create(id:, body:, **options)
          client.index(
            options.merge(index: index_name, type: type_name, id: id, body: body),
          )
        end
        alias create! create

        # Updates a document using the specified script.
        #
        #   UsersIndex::User.update!(id: 1, body: { script: { ... } }) # { '_id' => 1, ...}
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @param options [String, Integer] :id The `_id` of the elasticsearch document
        # @param options [Hash] :body the body of the request
        # @return [Hash] the elasticsearch response Hash
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/docs-update.html
        # def update!(id:, body:, **options)
        #   client.create(
        #     options.merge(index: index_name, type: type_name, id: id, body: body)
        #   )
        # end

        # Removes a JSON document from the specified index.
        #
        #   UsersIndex::User.delete!(id: 1) # true
        #   UsersIndex::User.delete!(id: 'missing') # raise Elasticsearch::Transport::Transport::Errors::NotFound
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @param options [String, Integer] :id The `_id` of the elasticsearch document
        # @raise [Elasticsearch::Transport::Transport::Errors::NotFound] when the doc does not exist
        # @return [Boolean] true when the operation is successfully completed
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/docs-delete.html
        def delete!(id:, **options)
          client.delete(options.merge(index: index_name, type: type_name, id: id))
        end

        # Removes a JSON document from the specified index.
        #
        #   UsersIndex::User.delete(id: 1) # true
        #   UsersIndex::User.delete(id: 'missing') # false
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @param options [String, Integer] :id The `_id` of the elasticsearch document
        # @raise [Elasticsearch::Transport::Transport::Errors::NotFound] when the doc does not exist
        # @return [Boolean] true when the operation is successfully completed
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/docs-delete.html
        def delete(id:, **options)
          delete!(id: id, **options)
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          false
        end

        # Gets the number of matches for a search query.
        #
        #   UsersIndex::User.count # 999
        #   UsersIndex::User.count(body: { ... }) # 32
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @param options [Hash] :body A query to restrict the results specified with the Query DSL (optional)
        # @return [Integer] amount of documents found
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/search-count.html
        def count(**options)
          response = client.count(options.merge(index: index_name, type: type_name))
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
        # @param options [String, Integer] :id The `_id` of the elasticsearch document
        # @return [Boolean] true if the document exists
        def exist?(id:, **options)
          client.exists(options.merge(index: index_name, type: type_name, id: id))
        end

        # Retrieves the specified JSON document from an index.
        #
        #   UsersIndex::User.find!(id: 1) # { '_id' => 1, ... }
        #   UsersIndex::User.find!(id: 'missing') # raise Elasticsearch::Transport::Transport::Errors::NotFound
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @param options [String, Integer] :id The `_id` of the elasticsearch document
        # @raise [Elasticsearch::Transport::Transport::Errors::NotFound] when the doc does not exist
        # @return [Hash] The elasticsearch document.
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/docs-get.html
        def find!(id:, **options)
          client.get(options.merge(index: index_name, type: type_name, id: id))
        end

        # Retrieves the specified JSON document from an index.
        #
        #   UsersIndex::User.find(id: 1) # { '_id' => 1, ... }
        #   UsersIndex::User.find(id: 'missing') # nil
        #
        # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
        # @param options [String, Integer] :id The `_id` of the elasticsearch document
        # @return [Hash, nil] The elasticsearch document
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/docs-get.html
        def find(id:, **options)
          find!(id: id, **options)
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          nil
        end
      end

      include InstanceMethods
    end
  end
end
