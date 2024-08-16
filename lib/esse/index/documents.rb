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

        # Backward compatibility while I change plugins using it
        update_lazy_attributes = options.delete(:lazy_update_document_attributes) if options.key?(:lazy_update_document_attributes)
        eager_load_lazy_attributes = options.delete(:eager_include_document_attributes) if options.key?(:eager_include_document_attributes)

        repo_hash.slice(*repo_types).each do |repo_name, repo|
          # Elasticsearch 6.x and older have multiple types per index.
          # This gem supports multiple types per index for backward compatibility, but we recommend to update
          # your elasticsearch to a at least 7.x version and use a single type per index.
          #
          # Note that the repository name will be used as the document type.
          # mapping_default_type
          bulk_kwargs = { suffix: suffix, type: repo_name, **options }
          cluster.may_update_type!(bulk_kwargs)

          lazy_attrs_to_eager_load = repo.lazy_document_attribute_names(eager_load_lazy_attributes)
          lazy_attrs_to_search_preload = repo.lazy_document_attribute_names(preload_lazy_attributes)
          lazy_attrs_to_update_after = repo.lazy_document_attribute_names(update_lazy_attributes)
          lazy_attrs_to_update_after -= lazy_attrs_to_eager_load
          lazy_attrs_to_search_preload -= lazy_attrs_to_eager_load

          # @TODO Refactor this by combining the upcoming code again with repo.each_serialized_batch as it was before:
          #     context[:lazy_attributes] = lazy_attrs_to_eager_load if lazy_attrs_to_eager_load.any?
          #     repo.each_serialized_batch(**context) do |batch|
          #       bulk(**bulk_kwargs, index: batch)

          #       lazy_attrs_to_update_after.each do |attr_name|
          #         partial_docs = repo.documents_for_lazy_attribute(attr_name, batch.reject(&:ignore_on_index?))
          #         next if partial_docs.empty?

          #         bulk(**bulk_kwargs, update: partial_docs)
          #       end
          #       count += batch.size
          #     end
          context ||= {}
          repo.send(:each_batch, **context) do |*args|
            batch, collection_context = args
            collection_context ||= {}
            entries = [*batch].map { |entry| repo.serialize(entry, **collection_context) }.compact

            if lazy_attrs_to_eager_load
              attrs = lazy_attrs_to_eager_load.is_a?(Array) ? lazy_attrs_to_eager_load : repo.lazy_document_attribute_names(lazy_attrs_to_eager_load)
              attrs.each do |attr_name|
                repo.retrieve_lazy_attribute_values(attr_name, entries).each do |doc_header, value|
                  doc = entries.find { |d| doc_header.id.to_s == d.id.to_s && doc_header.type == d.type && doc_header.routing == d.routing }
                  doc&.mutate(attr_name) { value }
                end
              end
            end

            preload_search_result = Hash.new { |h, arr_name| h[arr_name] = {} }
            if lazy_attrs_to_search_preload.any?
              hits = repo.index.search(query: {ids: {values: entries.map(&:id)} }, _source: lazy_attrs_to_search_preload).response.hits
              hits.each do |hit|
                doc_header = Esse::LazyDocumentHeader.coerce(hit.slice('_id', '_routing')) # TODO Add '_type', when adjusting eql to tread _doc properly
                next unless doc_header.valid?
                hit.dig('_source')&.each do |attr_name, attr_value|
                  real_attr_name = repo.lazy_document_attribute_names(attr_name).first
                  preload_search_result[real_attr_name][doc_header] = attr_value
                end
              end
              preload_search_result.each do |attr_name, values|
                values.each do |doc_header, value|
                  doc = entries.find { |d| doc_header.id.to_s == d.id.to_s && doc_header.type == d.type && doc_header.routing == d.routing }
                  doc&.mutate(attr_name) { value }
                end
              end
            end

            bulk(**bulk_kwargs, index: entries)

            lazy_attrs_to_update_after.each do |attr_name|
              preloaded_ids = preload_search_result[attr_name].keys
              filtered_docs = entries.reject do |doc|
                doc.ignore_on_index? || preloaded_ids.any? { |d| d.id.to_s == doc.id.to_s && d.type == doc.type && d.routing == doc.routing }
              end
              next if filtered_docs.empty?

              partial_docs = repo.documents_for_lazy_attribute(attr_name, filtered_docs)
              next if partial_docs.empty?

              bulk(**bulk_kwargs, update: partial_docs)
            end

            count += entries.size
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
