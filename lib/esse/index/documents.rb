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
          options[:body] = { doc: doc.mutated_source }
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
          options[:body] = doc.mutated_source
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

        to_index = []
        to_create = []
        to_update = []
        to_delete = []
        Esse::ArrayUtils.wrap(index).each do |doc|
          if doc.is_a?(Hash)
            to_index << doc
          elsif Esse.document?(doc) && !doc.ignore_on_index?
            hash = doc.to_bulk
            hash[:_type] ||= type if type
            to_index << hash
          end
        end
        Esse::ArrayUtils.wrap(create).each do |doc|
          if doc.is_a?(Hash)
            to_create << doc
          elsif Esse.document?(doc) && !doc.ignore_on_index?
            hash = doc.to_bulk
            hash[:_type] ||= type if type
            to_create << hash
          end
        end
        Esse::ArrayUtils.wrap(update).each do |doc|
          if doc.is_a?(Hash)
            to_update << doc
          elsif Esse.document?(doc) && !doc.ignore_on_index?
            hash = doc.to_bulk(operation: :update)
            hash[:_type] ||= type if type
            to_update << hash
          end
        end
        Esse::ArrayUtils.wrap(delete).each do |doc|
          if doc.is_a?(Hash)
            to_delete << doc
          elsif Esse.document?(doc) && !doc.ignore_on_delete?
            hash = doc.to_bulk(data: false)
            hash[:_type] ||= type if type
            to_delete << hash
          end
        end

        # @TODO Wrap the return in a some other Stats object with more information
        Esse::Import::Bulk.new(
          create: to_create,
          delete: to_delete,
          index: to_index,
          update: to_update,
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
      # @option [Boolean, Array<String>] :eager_load_lazy_attributes A list of lazy document attributes to include to the bulk index request.
      #   Or pass `true` to include all lazy attributes.
      # @option [Boolean, Array<String>] :update_lazy_attributes A list of lazy document attributes to bulk update each after the bulk import.
      #   Or pass `true` to update all lazy attributes.
      # @option [Boolean, Array<String>] :preload_lazy_attributes A list of lazy document attributes to preload using search API before the bulk import.
      #   Or pass `true` to preload all lazy attributes.
      # @return [Numeric] The number of documents imported
      def import(*repo_types, context: {}, eager_load_lazy_attributes: false, update_lazy_attributes: false, preload_lazy_attributes: false, suffix: nil, **options)
        repo_types = repo_hash.keys if repo_types.empty?
        count = 0

        if options.key?(:eager_include_document_attributes)
          warn 'The `eager_include_document_attributes` option is deprecated. Use `eager_load_lazy_attributes` instead.'
          eager_load_lazy_attributes = options.delete(:eager_include_document_attributes)
        end
        if options.key?(:lazy_update_document_attributes)
          warn 'The `lazy_update_document_attributes` option is deprecated. Use `update_lazy_attributes` instead.'
          update_lazy_attributes = options.delete(:lazy_update_document_attributes)
        end

        repo_hash.slice(*repo_types).each do |repo_name, repo|
          # Elasticsearch 6.x and older have multiple types per index.
          # This gem supports multiple types per index for backward compatibility, but we recommend to update
          # your elasticsearch to a at least 7.x version and use a single type per index.
          #
          # Note that the repository name will be used as the document type.
          # mapping_default_type
          bulk_kwargs = { suffix: suffix, type: repo_name, **options }
          cluster.may_update_type!(bulk_kwargs)

          context ||= {}
          context[:eager_load_lazy_attributes] = eager_load_lazy_attributes
          context[:preload_lazy_attributes] = preload_lazy_attributes
          repo.each_serialized_batch(**context) do |batch|
            bulk(**bulk_kwargs, index: batch)

            if update_lazy_attributes != false
              attrs = repo.lazy_document_attribute_names(update_lazy_attributes)
              attrs -= repo.lazy_document_attribute_names(eager_load_lazy_attributes)
              update_attrs = attrs.each_with_object(Hash.new { |h, k| h[k] = {} }) do |attr_name, memo|
                filtered_docs = batch.reject do |doc|
                  doc.ignore_on_index? || doc.mutations.key?(attr_name)
                end
                next if filtered_docs.empty?

                repo.retrieve_lazy_attribute_values(attr_name, filtered_docs).each do |doc, value|
                  memo[doc.doc_header][attr_name] = value
                end
              end
              if update_attrs.any?
                bulk_update = update_attrs.map do |header, values|
                  header.merge(data: {doc: values})
                end
                bulk(**bulk_kwargs, update: bulk_update)
              end
            end

            count += batch.size
          end
        end
        count
      end

      # Update documents by query
      #
      # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
      # @option [String, nil] :suffix The index suffix. Defaults to the nil.
      #
      # @return [Hash] The elasticsearch response hash
      def update_by_query(suffix: nil, **options)
        definition = {
          index: index_name(suffix: suffix),
        }.merge(options)
        cluster.may_update_type!(definition)
        cluster.api.update_by_query(**definition)
      end

      # Delete documents by query
      #
      # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
      # @option [String, nil] :suffix The index suffix. Defaults to the nil.
      #
      # @return [Hash] The elasticsearch response hash
      def delete_by_query(suffix: nil, **options)
        definition = {
          index: index_name(suffix: suffix),
        }.merge(options)
        cluster.may_update_type!(definition)
        cluster.api.delete_by_query(**definition)
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
