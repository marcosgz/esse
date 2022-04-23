# frozen_string_literal: true

module Esse
  # Type is actually deprecated. Elasticsearch today uses _doc instead of type
  # And in upcoming release it will be totally removed.
  # But I want to keep compatibility with old versions of es.
  class IndexType
    class << self
      # This methods should be defined using meta programming in the index type definition
      # @see Esse::Index::Type.define_type
      attr_reader :index, :type_name
    end
    require_relative 'index_type/actions'
    require_relative 'index_type/mappings'
    require_relative 'index_type/backend'
    require_relative 'index_type/odm'
  end
end
