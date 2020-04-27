# frozen_string_literal: true

require 'forwardable'

module Esse
  module Backend
    class IndexType
      require_relative 'index_type/documents'

      extend Forwardable

      # Type delegators
      def_delegators :@index_type, :type_name, :each_serialized_batch, :serialize
      # Index delegators
      def_delegators :index_class, :index_name

      def initialize(type)
        @index_type = type
      end

      protected

      def index_class
        @index_type.index
      end

      def client
        index_class.cluster.client
      end
    end
  end
end
