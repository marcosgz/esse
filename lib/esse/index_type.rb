# frozen_string_literal: true

require_relative 'object_document_mapper'

module Esse
  # Type is actually deprecated. Elasticsearch today uses _doc instead of type
  # And in upcoming release it will be totally removed.
  # But I want to keep compatibility with old versions of es.
  class IndexType
    require_relative 'index_type/actions'
    require_relative 'index_type/mappings'
    require_relative 'index_type/backend'
    extend ObjectDocumentMapper
  end
end
