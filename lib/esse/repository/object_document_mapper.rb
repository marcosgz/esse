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

      # Wrap collection data into serialized batches
      #
      # @param [Hash] kwargs The context
      # @return [Enumerator] The enumerator
      # @yield [Array, **context] serialized collection and the optional context from the collection
      def each_serialized_batch(**kwargs, &block)
        each_batch(**kwargs) do |*args|
          batch, collection_context = args
          collection_context ||= {}
          entries = [*batch].map { |entry| serialize(entry, **collection_context) }.compact
          block.call(entries, **kwargs)
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
          each_serialized_batch(**kwargs) do |docs, **_collection_kargs|
            docs.each { |document| yielder.yield(document) }
          end
        end
      end

      def lazy_document_attributes
        @lazy_document_attributes ||= {}.freeze
      end

      def lazy_document_attribute?(attr_name)
        lazy_document_attributes.key?(attr_name.to_s)
      end

      def fetch_lazy_document_attribute(attr_name)
        klass, kwargs = lazy_document_attributes.fetch(attr_name.to_s)
        klass.new(**kwargs)
      rescue KeyError
        raise ArgumentError, format('Attribute %<attr>p is not defined as a lazy document attribute', attr: attr_name)
      end

      def lazy_document_attribute(attr_name, klass = nil, **kwargs, &block)
        if lazy_document_attribute?(attr_name)
          raise ArgumentError, format('Attribute %<attr>p is already defined as a lazy document attribute', attr: attr_name)
        end

        @lazy_document_attributes = lazy_document_attributes.dup
        if block
          klass = Class.new(Esse::DocumentLazyAttribute) do
            define_method(:call, &block)
          end
          @lazy_document_attributes[attr_name.to_s] = [klass, kwargs]
        elsif klass.is_a?(Class) && klass <= Esse::DocumentLazyAttribute
          @lazy_document_attributes[attr_name.to_s] = [klass, kwargs]
        elsif klass.is_a?(Class) && klass.instance_methods.include?(:call)
          @lazy_document_attributes[attr_name.to_s] = [klass, kwargs]
        elsif klass.nil?
          raise ArgumentError, format('A block or a class that responds to `call` is required to define a lazy document attribute')
        else
          raise ArgumentError, format('%<arg>p is not a valid lazy document attribute. Class should inherit from Esse::DocumentLazyAttribute or respond to `call`', arg: klass)
        end
      ensure
        @lazy_document_attributes&.freeze
      end
    end

    extend ClassMethods
  end
end
