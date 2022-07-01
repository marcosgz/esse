# frozen_string_literal: true

module Esse
  # Type is actually deprecated. Elasticsearch today uses _doc instead of type
  # And in upcoming release it will be totally removed.
  # But I want to keep compatibility with old versions of es.
  class Repository
    class << self
      # This methods should be defined using meta programming in the index type definition
      # @see Esse::Index::Type.repository
      attr_reader :index, :type_name
    end
    require_relative 'repository/actions'
    require_relative 'repository/mappings'
    require_relative 'repository/backend'
    require_relative 'repository/object_document_mapper'
  end
end
