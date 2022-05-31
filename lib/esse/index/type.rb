# frozen_string_literal: true

module Esse
  class Index
    module ClassMethods
      attr_writer :type_hash

      def type_hash
        @type_hash ||= {}
      end

      def define_type(type_name, *_args, &block)
        type_class = Class.new(Esse::IndexType)

        const_set(Hstring.new(type_name).camelize.demodulize.to_s, type_class)

        index = self

        type_class.send(:define_singleton_method, :index) { index }
        type_class.send(:define_singleton_method, :type_name) { type_name.to_s }

        type_class.class_eval(&block) if block

        self.type_hash = type_hash.merge(type_class.type_name => type_class)
        type_class
      end
    end

    extend ClassMethods
  end
end
