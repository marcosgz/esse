# frozen_string_literal: true

module Esse
  class Index
    @type_hash = {}
    @setting = {}
    @mapping = {}
    @plugins = []
    @cluster_id = nil

    require_relative 'index/plugins'
    require_relative 'index/base'
    require_relative 'index/inheritance'
    require_relative 'index/actions'
    require_relative 'index/attributes'
    require_relative 'index/type'
    require_relative 'index/settings'
    require_relative 'index/mappings'
    require_relative 'index/descendants'
    require_relative 'index/backend'
    require_relative 'index/object_document_mapper'

    def_Index(::Esse)
  end
end
