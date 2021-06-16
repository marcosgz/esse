# frozen_string_literal: true

require_relative 'core'
require_relative 'object_document_mapper'

module Esse
  class Index
    require_relative 'index/base'
    require_relative 'index/inheritance'
    require_relative 'index/actions'
    require_relative 'index/naming'
    require_relative 'index/type'
    require_relative 'index/settings'
    require_relative 'index/mappings'
    require_relative 'index/descendants'
    require_relative 'index/backend'
    extend ObjectDocumentMapper

    @cluster_id = nil

    def_Index(::Esse)
  end
end
