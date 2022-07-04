# frozen_string_literal: true

module Esse
  # Type is actually deprecated. Elasticsearch today uses _doc instead of type
  # And in upcoming release it will be totally removed.
  # But I want to keep compatibility with old versions of es.
  class Repository
    class << self
      extend Gem::Deprecate

      # This methods will be defined using meta programming in the index respository definition
      # @see Esse::Index::Type.repository
      attr_reader :index
      attr_accessor :document_type

      def type_name
        document_type
      end
      deprecate :type_name, :document_type, 2022, 8
    end
    require_relative 'repository/actions'
    require_relative 'repository/mappings'
    require_relative 'repository/backend'
    require_relative 'repository/object_document_mapper'
  end
end
