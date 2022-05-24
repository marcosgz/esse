# frozen_string_literal: true

module Esse
  class Index
    module ObjectDocumentMapper
      DEFAULT_DOC_TYPE = :__default__

      # Convert ruby object to json. Arguments will be same of passed through the
      # collection. It's allowed a block or a class with the `to_h` instance method.
      # Example with block
      #   serializer do |model, **context|
      #     {
      #       id: model.id,
      #       admin: context[:is_admin],
      #     }
      #   end
      # Example with serializer class
      #   serializer UserSerializer
      def serializer(*args, &block)
        doc_type, klass = args
        # >> Backward compatibility for the old collection syntax without explicit doc_type
        if doc_type && !doc_type.is_a?(Symbol)
          klass = doc_type
          doc_type = DEFAULT_DOC_TYPE
        end
        doc_type = doc_type&.to_sym || DEFAULT_DOC_TYPE
        # <<

        @serializer_proc ||= {}
        if @serializer_proc.key?(doc_type)
          raise ArgumentError, format('Serializer for %p already defined', doc_type)
        end

        if block
          @serializer_proc[doc_type] = block
        elsif klass.is_a?(Class) && klass.instance_methods.include?(:to_h)
          @serializer_proc[doc_type] = proc { |*args, **kwargs| klass.new(*args, **kwargs).to_h }
        elsif klass.is_a?(Class) && klass.instance_methods.include?(:as_json) # backward compatibility
          @serializer_proc[doc_type] = proc { |*args, **kwargs| klass.new(*args, **kwargs).as_json }
        elsif klass.is_a?(Class) && klass.instance_methods.include?(:call)
          @serializer_proc[doc_type] = proc { |*args, **kwargs| klass.new(*args, **kwargs).call }
        else
          msg = format('%<arg>p is not a valid serializer. The serializer should ' \
                        'respond with `to_h` instance method.', arg: klass,)
          raise ArgumentError, msg
        end
      end

      # Convert ruby object to json by using the serializer of the given document type.
      # @param [Symbol] doc_type The document type
      # @param [Object] model The ruby object
      # @param [Hash] kwargs The context
      # @return [Hash] The json object
      def serialize(*args, **kwargs)
        doc_type, model = args
        # >> Backward compatibility for the old collection syntax without explicit doc_type
        if doc_type && !doc_type.is_a?(Symbol)
          model = doc_type
          doc_type = DEFAULT_DOC_TYPE
        end
        doc_type = doc_type&.to_sym || DEFAULT_DOC_TYPE
        # <<

        if @serializer_proc.nil? || @serializer_proc[doc_type].nil?
          raise NotImplementedError, format('there is no %<t>p serializer defined for the %<k>p index', t: doc_type, k: to_s)
        end

        @serializer_proc.fetch(doc_type).call(model, **kwargs)
      end

      # Used to define the source of data. A block is required. And its
      # content should yield an array of each object that should be serialized.
      # The list of arguments will be passed throught the serializer method.
      #
      # Example:
      #   collection :admin, AdminStore
      #   collection :user do |**conditions, &block|
      #     User.where(conditions).find_in_batches(batch_size: 5000) do |batch|
      #       block.call(batch, conditions)
      #     end
      #   end
      #
      # @param [Symbol] name The name of the collection.
      # @param [Class] klass The class of the collection. (Optional when block is passed)
      # @param [Proc] block The block that will be used to iterate over the collection. (Optional when using a class)
      # @return [void]
      def collection(*args, &block)
        doc_type, collection_klass = args
        # >> Backward compatibility for the old collection syntax without explicit doc_type
        if doc_type && !doc_type.is_a?(Symbol) && !doc_type.is_a?(String) && collection_klass.nil? && @collection_proc.nil?
          collection_klass = doc_type
          doc_type = DEFAULT_DOC_TYPE
        end
        doc_type = doc_type&.to_sym || DEFAULT_DOC_TYPE
        # <<

        if collection_klass.nil? && block.nil?
          raise ArgumentError, 'a document type, followed by a collection class or block that stream the data ' \
                              'is required to define the collection'
        end

        if block.nil? && collection_klass.is_a?(Class) && !collection_klass.include?(Enumerable)
          msg = '%<arg>p is not a valid collection class.' \
                ' Collections should implement the Enumerable interface.'
          raise ArgumentError, format(msg, arg: collection_klass)
        end

        @collection_proc ||= {}
        @collection_proc[doc_type] = collection_klass || block
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
      # @param [Symbol] doc_type The document type
      # @param [Hash] kwargs The context
      # @param [Proc] block The block that will be used to iterate over the collection.
      # @return [void]
      def each_batch(doc_type = DEFAULT_DOC_TYPE, *args, **kwargs, &block)
        doc_type = doc_type&.to_sym || DEFAULT_DOC_TYPE

        if @collection_proc.nil? || @collection_proc[doc_type].nil?
          raise NotImplementedError, format('there is no %<t>p collection defined for the %<k>p index', t: doc_type, k: to_s)
        end

        collection_proc = @collection_proc.fetch(doc_type)
        case collection_proc
        when Class
          collection_proc.new(*args, **kwargs).each(&block)
        else
          collection_proc.call(*args, **kwargs, &block)
        end
      rescue LocalJumpError
        raise(SyntaxError, 'block must be explicitly declared in the collection definition')
      end

      # Wrap collection data into serialized batches
      #
      # @param [Symbol] doc_type The document type
      # @param [Hash] kwargs The context
      # @return [Enumerator] The enumerator
      # @yield [Array, **context] serialized collection and the optional context from the collection
      def each_serialized_batch(doc_type = DEFAULT_DOC_TYPE, **kwargs, &block)
        each_batch(doc_type, **kwargs) do |*args|
          batch, collection_context = args
          collection_context ||= {}
          entries = [*batch].map { |entry| serialize(doc_type, entry, **collection_context) }.compact
          block.call(entries, **kwargs)
        end
      end

      # Wrap collection data into serialized documents
      #
      # Example:
      #    GeosIndex.documents(id: 1).first
      #
      # @return [Enumerator] All serialized entries
      def documents(doc_type = DEFAULT_DOC_TYPE, **kwargs)
        Enumerator.new do |yielder|
          each_serialized_batch(doc_type, **kwargs) do |documents, **_collection_kargs|
            documents.each { |document| yielder.yield(document) }
          end
        end
      end
    end

    extend ObjectDocumentMapper
  end
end
