# frozen_string_literal: true

require 'forwardable'

module Esse
  module Backend
    class IndexType
      require_relative 'index_type/documents'

      extend Forwardable

      # Type delegators
      def_delegators :@index_type, :type_name, :index
      # Index delegators
      def_delegators :index, :index_name

      def initialize(type)
        @index_type = type
      end

      protected

      def client
        index.elasticsearch_client
      end
    end
  end
end
