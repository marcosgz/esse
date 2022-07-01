# frozen_string_literal: true

module Esse
  # Delegates all the methods to the index ODM by prepending the type name.
  #
  # @see ObjectDocumentMapper
  class IndexType
    module ClassMethods
      def serializer(klass = nil, &block)
        index.serializer(type_name.to_sym, klass, &block)
      end

      def serialize(model, **kwargs)
        index.serialize(type_name.to_sym, model, **kwargs)
      end

      def collection(klass = nil, &block)
        index.collection(type_name.to_sym, klass, &block)
      end

      def each_batch(**kwargs, &block)
        index.each_batch(type_name.to_sym, **kwargs, &block)
      end

      def each_serialized_batch(**kwargs, &block)
        index.each_serialized_batch(type_name.to_sym, **kwargs, &block)
      end

      def documents(**kwargs)
        index.documents(type_name.to_sym, **kwargs)
      end
    end

    extend ClassMethods
  end
end