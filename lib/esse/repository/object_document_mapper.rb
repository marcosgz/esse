# frozen_string_literal: true

module Esse
  # Delegates all the methods to the index ODM by prepending the type name.
  #
  # @see ObjectDocumentMapper
  class Repository
    module ClassMethods
      # Define the document type that will be used to serialize the data.
      # Arguments will be same of passed through the collection. It's allowed a block or a class with the `to_h` instance method.
      # Example with block
      #   document do |model, **context|
      #     {
      #       id: model.id,
      #       admin: context[:is_admin],
      #     }
      #   end
      # Example with document class
      #   document UserDocument
      def document(klass = nil, &block)
        if @document_proc
          raise ArgumentError, format('Document for %p already defined', repo_name)
        end

        if block
          @document_proc = ->(model, **kwargs) { coerce_to_document(block.call(model, **kwargs)) }
        elsif klass.is_a?(Class) && klass <= Esse::Document
          @document_proc = ->(model, **kwargs) { klass.new(model, **kwargs) }
        elsif klass.is_a?(Class) && klass.instance_methods.include?(:to_h)
          @document_proc = ->(model, **kwargs) { coerce_to_document(klass.new(model, **kwargs).to_h) }
        elsif klass.is_a?(Class) && klass.instance_methods.include?(:as_json) # backward compatibility
          @document_proc = ->(model, **kwargs) { coerce_to_document(klass.new(model, **kwargs).as_json) }
        elsif klass.is_a?(Class) && klass.instance_methods.include?(:call)
          @document_proc = ->(model, **kwargs) { coerce_to_document(klass.new(model, **kwargs).call) }
        else
          msg = format("%<arg>p is not a valid document. The document should inherit from Esse::Document or respond to `to_h'", arg: klass)
          raise ArgumentError, msg
        end
      end

      # Used to define the source of data. A block is required. And its
      # content should yield an array of each object that should be serialized.
      # The list of arguments will be passed throught the document method.
      #
      # Example:
      #   collection AdminStore
      #   collection do |**conditions, &block|
      #     User.where(conditions).find_in_batches(batch_size: 5000) do |batch|
      #       block.call(batch, conditions)
      #     end
      #   end
      #
      # @param [String] name The identification of the collection.
      # @param [Class] klass The class of the collection. (Optional when block is passed)
      # @param [Proc] block The block that will be used to iterate over the collection. (Optional when using a class)
      # @return [void]
      def collection(collection_klass = nil, **_, &block)
        if collection_klass.nil? && block.nil?
          raise ArgumentError, 'a document type, followed by a collection class or block that stream the data ' \
                              'is required to define the collection'
        end

        if block.nil? && collection_klass.is_a?(Class) && !collection_klass.include?(Enumerable)
          msg = '%<arg>p is not a valid collection class.' \
                ' Collections should implement the Enumerable interface.'
          raise ArgumentError, format(msg, arg: collection_klass)
        end

        @collection_proc = collection_klass || block
      end

      # Expose the collection class to let external plugins and extensions to access it.
      # @return [Class, nil] The collection class
      # IDEA: When collection is defined as a block, it should setup a class with the block content.
      def collection_class
        return unless @collection_proc.is_a?(Class)

        @collection_proc
      end

      # Wrap collection data into serialized batches
      #
      # @param [Hash] kwargs The context
      # @return [Enumerator] The enumerator
      # @yield [Array, **context] serialized collection and the optional context from the collection
      def each_serialized_batch(eager_load_lazy_attributes: false, preload_lazy_attributes: false, **kwargs)
        if kwargs.key?(:lazy_attributes)
          warn 'The `lazy_attributes` option is deprecated. Use `eager_load_lazy_attributes` instead.'
          eager_load_lazy_attributes = kwargs.delete(:lazy_attributes)
        end

        lazy_attrs_to_eager_load = lazy_document_attribute_names(eager_load_lazy_attributes)
        lazy_attrs_to_search_preload = lazy_document_attribute_names(preload_lazy_attributes)
        lazy_attrs_to_search_preload -= lazy_attrs_to_eager_load

        each_batch(**kwargs) do |*args|
          batch, collection_context = args
          collection_context ||= {}
          entries = [*batch].map { |entry| serialize(entry, **collection_context) }.compact
          lazy_attrs_to_eager_load.each do |attr_name|
            retrieve_lazy_attribute_values(attr_name, entries).each do |doc_header, value|
              doc = entries.find { |d| d.eql?(doc_header, match_lazy_doc_header: true) }
              doc&.mutate(attr_name) { value }
            end
          end

          if lazy_attrs_to_search_preload.any?
            entries.group_by(&:routing).each do |routing, docs|
              search_request = {
                query: { ids: { values: docs.map(&:id) } },
                size: docs.size,
                _source: lazy_attrs_to_search_preload
              }
              search_request[:routing] = routing if routing
              index.search(**search_request).response.hits.each do |hit|
                header = [hit['_id'], hit['_routing'], hit['_type']]
                next if header[0].nil?

                hit.dig('_source')&.each do |attr_name, attr_value|
                  real_attr_name = lazy_document_attribute_names(attr_name).first
                  next if real_attr_name.nil?

                  doc = entries.find { |d| Esse.document_match_with_header?(d, *header) }
                  doc&.mutate(real_attr_name) { attr_value }
                end
              end
            end
          end

          yield entries
        end
      end

      # Wrap collection data into serialized documents
      #
      # Example:
      #    GeosIndex.documents(id: 1).first
      #
      # @return [Enumerator] All serialized entries
      def documents(**kwargs)
        Enumerator.new do |yielder|
          each_serialized_batch(**kwargs) do |docs|
            docs.each { |document| yielder.yield(document) }
          end
        end
      end

      # Convert ruby object to json by using the document of the given document type.
      # @param [Object] model The ruby object
      # @param [Hash] kwargs The context
      # @return [Esse::Document] The serialized document
      def serialize(model, **kwargs)
        if @document_proc.nil?
          raise NotImplementedError, format('there is no %<t>p document defined for the %<k>p index', t: repo_name, k: index.to_s)
        end

        @document_proc.call(model, **kwargs)
      end

      # Used to fetch batches of ids from the collection that implement the `each_batch_ids` method.
      #
      # @param [Hash] kwargs The context
      # @yield [Array] A batch of document IDs to be processed.
      # @raise [NotImplementedError] if the collection does not implement the `each_batch_ids` method.
      # @raise [NotImplementedError] if the collection is not defined.
      # @return [Enumerator] The enumerator
      # @example
      #   each_batch_ids(active: true) do |ids|
      #     puts ids.size
      #   end
      def each_batch_ids(*args, **kwargs)
        if @collection_proc.nil?
          raise NotImplementedError, format('there is no %<t>p collection defined for the %<k>p index', t: repo_name, k: index.to_s)
        end

        if @collection_proc.is_a?(Class) && @collection_proc.method_defined?(:each_batch_ids)
          colection_instance = @collection_proc.new(*args, **kwargs)
          if block_given?
            colection_instance.each_batch_ids { |ids| yield ids }
          else
            Enumerator.new do |yielder|
              colection_instance.each_batch_ids { |ids| yielder.yield ids }
            end
          end
        else
          Kernel.warn(<<~MSG)
            The public `#each_batch_ids' method is not available for the collection defined in the #{repo_name} index.

            The `#each' method will be used instead, which may lead to performance degradation because it serializes the entire document
            to only obtain the IDs. Consider implementing a public `#each_batch_ids' method in your collection class for better performance.

            Example implementation taking into account you are dealing with an ActiveRecord model:
              class UserCollection < Esse::Collection
                # ....

                def each_batch_ids
                  user_query.except(:includes, :preload, :eager_load).in_batches do |batch|
                    yield batch.pluck(:id)
                  end
                end
              end
          MSG

          enumerator = Enumerator.new do |yielder|
            each_batch(*args, **kwargs) do |*batch_args|
              batch, collection_context = batch_args
              collection_context ||= {}
              ids = [*batch].map { |entry| serialize(entry, **collection_context)&.id }.compact
              yielder.yield(ids) if ids.any?
            end
          end
          return enumerator unless block_given?

          enumerator.each { |ids| yield ids }
        end
      rescue LocalJumpError
        raise(SyntaxError, 'block must be explicitly declared in the collection definition')
      end

      protected

      def coerce_to_document(value)
        case value
        when Esse::Document
          value
        when Hash
          Esse::HashDocument.new(value)
        when NilClass, FalseClass
          Esse::NullDocument.new
        else
          raise ArgumentError, format('%<arg>p is not a valid document. The document should be a hash or an instance of Esse::Document', arg: value)
        end
      end

      # Used to fetch all batch of data defined on the collection model.
      # Arguments can be anything. They will just be passed through the block.
      # Useful when the collection depends on scope or any other conditions
      #
      # Example:
      #   each_batch(active: true) do |data, **_collection_opts|
      #     puts data.size
      #   end
      #
      # @todo Remove *args. It should only support keyword arguments
      #
      # @param [Hash] kwargs The context
      # @param [Proc] block The block that will be used to iterate over the collection.
      # @return [void]
      def each_batch(*args, **kwargs, &block)
        if @collection_proc.nil?
          raise NotImplementedError, format('there is no %<t>p collection defined for the %<k>p index', t: repo_name, k: index.to_s)
        end

        case @collection_proc
        when Class
          @collection_proc.new(*args, **kwargs).each(&block)
        else
          @collection_proc.call(*args, **kwargs, &block)
        end
      rescue LocalJumpError
        raise(SyntaxError, 'block must be explicitly declared in the collection definition')
      end
    end

    extend ClassMethods
  end
end
