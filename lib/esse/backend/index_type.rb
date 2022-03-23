# frozen_string_literal: true

require 'forwardable'

module Esse
  module Backend
    class IndexType
      require_relative 'index_type/documents'

      extend Forwardable

      # Type delegators
      def_delegators :@index_type, :type_name, :each_serialized_batch, :serialize

      def initialize(type)
        @index_type = type
      end

      protected

      def index_name(suffix: nil)
        suffix = Hstring.new(suffix).underscore.presence
        return index_class.index_name unless suffix

        [index_class.index_name, suffix].join('_')
      end

      def index_class
        @index_type.index
      end

      def client
        index_class.cluster.client
      end

      def bulk_wait_interval
        index_class.bulk_wait_interval
      end
    end
  end
end
