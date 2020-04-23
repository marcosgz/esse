# frozen_string_literal: true

module Esse
  class Index
    module ClassMethods
      def index_name=(value)
        @index_name = index_prefixed_name(value)
      end

      def index_name
        @index_name || index_prefixed_name(normalized_name)
      end

      def index_name?
        !index_name.nil?
      end

      protected

      def index_prefixed_name(value)
        return if value == '' || value.nil?
        return value.to_s unless Esse.config.index_prefix

        [Esse.config.index_prefix, value].join('_')
      end

      def normalized_name
        Hstring.new(name).demodulize.underscore.sub(/_(index)$/, '')
      end
    end

    extend ClassMethods
  end
end
