# frozen_string_literal: true

module Esse
  class Index
    module ClassMethods
      # Retrieves the specified JSON document from an index.
      #
      #   UsersIndex.get(id: 1) # { '_id' => 1, ... }
      #   UsersIndex.get(id: 'missing') # raise Esse::Transport::NotFoundError
      #
      # @param doc [Esse::Document] the document to retrieve
      # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
      # @option [String, Integer] :id The `_id` of the elasticsearch document
      # @option [String, NilClass] :type The type of the document (Optional for elasticsearch >= 7)
      # @option [String, nil] :suffix The index suffix. Defaults to the nil.
      # @raise [Esse::Transport::NotFoundError] when the doc does not exist
      # @return [Hash] The elasticsearch document.
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/docs-get.html
      def get(doc = nil, suffix: nil, **options)
        if document?(doc)
          options[:id] = doc.id
          options[:type] = doc.type if doc.type?
          options[:routing] = doc.routing if doc.routing?
        end
        require_kwargs!(options, :id)
        options[:index] = index_name(suffix: suffix)
        cluster.may_update_type!(options)
        cluster.api.get(**options)
      end

      # Check if a JSON document exists
      #
      #   UsersIndex.exist?(id: 1) # true
      #   UsersIndex.exist?(id: 'missing') # false
      #
      # @param doc [Esse::Document] the document to retrieve
      # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
      # @option [String, Integer] :id The `_id` of the elasticsearch document
      # @option [String, NilClass] :type The type of the document (Optional for elasticsearch >= 7)
      # @option [String, nil] :suffix The index suffix. Defaults to the nil.
      # @return [Boolean] true if the document exists
      def exist?(doc = nil, suffix: nil, **options)
        if document?(doc)
          options[:id] = doc.id
          options[:type] = doc.type if doc.type?
          options[:routing] = doc.routing if doc.routing?
        end
        require_kwargs!(options, :id)
        options[:index] = index_name(suffix: suffix)
        cluster.may_update_type!(options)
        cluster.api.exist?(**options)
      end

      # Gets the number of matches for a search query.
      #
      #   UsersIndex.count # 999
      #   UsersIndex.count(body: { ... }) # 32
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
          type: type,
        }
        cluster.may_update_type!(params)
        cluster.api.count(**options, **params)['count']
      end

      # Removes a JSON document from the specified index.
      #
      #   UsersIndex.delete(id: 1) # true
      #   UsersIndex.delete(id: 'missing') # false
      #
      # @param doc [Esse::Document] the document to retrieve
      # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
      # @option [String, Integer] :id The `_id` of the elasticsearch document
      # @option [String, NilClass] :type The type of the document (Optional for elasticsearch >= 7)
      # @option [String, nil] :suffix The index suffix. Defaults to the nil.
      # @raise [Esse::Transport::NotFoundError] when the doc does not exist
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/docs-delete.html
      def delete(doc = nil, suffix: nil, **options)
        if document?(doc)
          options[:id] = doc.id
          options[:type] = doc.type if doc.type?
          options[:routing] = doc.routing if doc.routing?
        end
        require_kwargs!(options, :id)
        options[:index] = index_name(suffix: suffix)
        cluster.may_update_type!(options)
        cluster.api.delete(**options)
      end

      # Updates a document using the specified script.
      #
      #   UsersIndex.update(id: 1, body: { doc: { ... } }) # { '_id' => 1, ...}
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
      def update(doc = nil, suffix: nil, **options)
        if document?(doc)
          options[:id] = doc.id
          options[:body] = { doc: doc.source }
          options[:type] = doc.type if doc.type?
          options[:routing] = doc.routing if doc.routing?
        end
        require_kwargs!(options, :id, :body)
        options[:index] = index_name(suffix: suffix)
        cluster.may_update_type!(options)
        cluster.api.update(**options)
      end

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
      def index(doc = nil, suffix: nil, **options)
        if document?(doc)
          options[:id] = doc.id
          options[:body] = doc.source
          options[:type] = doc.type if doc.type?
          options[:routing] = doc.routing if doc.routing?
        end
        require_kwargs!(options, :id, :body)
        options[:index] = index_name(suffix: suffix)
        cluster.may_update_type!(options)
        cluster.api.index(**options)
      end

      # Performs multiple indexing or delete operations in a single API call.
      # This reduces overhead and can greatly increase indexing speed.
      #
      # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
      # @option [String, nil] :suffix The index suffix. Defaults to the nil.
      # @option [Array<Esse::Document>] :index list of documents to be indexed(Optional)
      # @option [Array<Esse::Document>] :delete list of documents to be deleted(Optional)
      # @option [Array<Esse::Document>] :create list of documents to be created(Optional)
      # @option [String, NilClass] :type The type of the document (Optional for elasticsearch >= 7)
      # @return [Array<Esse::Import::RequestBody>] The list of request bodies. @TODO Change this to a Stats object
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/docs-bulk.html
      # @see https://github.com/elastic/elasticsearch-ruby/blob/main/elasticsearch-api/lib/elasticsearch/api/utils.rb
      # @see https://github.com/elastic/elasticsearch-ruby/blob/main/elasticsearch-api/lib/elasticsearch/api/actions/bulk.rb
      def bulk(create: nil, delete: nil, index: nil, update: nil, type: nil, suffix: nil, **options)
        definition = {
          index: index_name(suffix: suffix),
          type: type,
        }.merge(options)
        cluster.may_update_type!(definition)

        # @TODO Wrap the return in a some other Stats object with more information
        Esse::Import::Bulk.new(
          **definition.slice(:type),
          create: create,
          delete: delete,
          index: index,
          update: update,
        ).each_request do |request_body|
          cluster.api.bulk(**definition, body: request_body.body) do |event_payload|
            event_payload[:body_stats] = request_body.stats
            if bulk_wait_interval > 0
              event_payload[:wait_interval] = bulk_wait_interval
              sleep(bulk_wait_interval)
            else
              event_payload[:wait_interval] = 0.0
            end
          end
        end
      end

      # Resolve collection and index data
      #
      # @param repos [Array<String>] List of repo types. Defaults to all types.
      # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
      # @option [String, nil] :suffix The index suffix. Defaults to the nil.
      # @option [Hash] :context The collection context. This value will be passed as argument to the collection
      #   May be SQL condition or any other filter you have defined on the collection.
      # @return [Numeric] The number of documents imported
      def import(*repo_types, context: {}, eager_include_document_attributes: false, lazy_update_document_attributes: false, suffix: nil, **options)
        repo_types = repo_hash.keys if repo_types.empty?
        count = 0
        repo_hash.slice(*repo_types).each do |repo_name, repo|
          repo.each_serialized_batch(**(context || {})) do |batch|
            # Elasticsearch 6.x and older have multiple types per index.
            # This gem supports multiple types per index for backward compatibility, but we recommend to update
            # your elasticsearch to a at least 7.x version and use a single type per index.
            #
            # Note that the repository name will be used as the document type.
            # mapping_default_type
            kwargs = { suffix: suffix, type: repo_name, **options }
            cluster.may_update_type!(kwargs)

            doc_attrs = {eager: [], lazy: []}
            if (expected = eager_include_document_attributes) != false
              allowed = repo.lazy_document_attributes.keys
              doc_attrs[:eager] = (expected == true) ? allowed : Array(expected).map(&:to_s) & allowed
            end
            if (expected = lazy_update_document_attributes) != false
              allowed = repo.lazy_document_attributes.keys
              doc_attrs[:lazy] = (expected == true) ? allowed : Array(expected).map(&:to_s) & allowed
              doc_attrs[:lazy] -= doc_attrs[:eager]
            end

            doc_attrs[:eager].each do |attr_name|
              partial_docs = repo.documents_for_lazy_attribute(attr_name, *batch.reject(&:ignore_on_index?))
              next if partial_docs.empty?

              partial_docs.each do |part_doc|
                doc = batch.find { |d| part_doc.id == d.id && part_doc.type == d.type && part_doc.routing == d.routing }
                next unless doc

                doc.send(:__add_lazy_data_to_source__, part_doc.source)
              end
            end

            bulk(**kwargs, index: batch)

            doc_attrs[:lazy].each do |attr_name|
              partial_docs = repo.documents_for_lazy_attribute(attr_name, *batch.reject(&:ignore_on_index?))
              next if partial_docs.empty?

              bulk(**kwargs, update: partial_docs)
            end

            count += batch.size
          end
        end
        count
      end

      protected

      def document?(doc)
        Esse.document?(doc)
      end

      def require_kwargs!(options, *keys)
        keys.each do |key|
          raise ArgumentError, "missing keyword: #{key}" unless options.key?(key)
        end
      end
    end

    extend ClassMethods
  end
end
