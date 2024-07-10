# frozen_string_literal: true

module Esse
  # Definition for the lazy document attributes
  class Repository
    module ClassMethods
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
