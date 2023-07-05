# frozen_string_literal: true

module Esse
  class HashDocument < Esse::Document
    META_KEYS = %i[_id _type _routing routing].freeze

    def initialize(object)
      @object = object
      @options = {}
    end

    # @return [String, Number] the document ID
    def id
      object['_id'] || object[:_id] || object['id'] || object[:id]
    end

    # @return [String, nil] the document type
    def type
      object['_type'] || object[:_type]
    end

    # @return [String, nil] the document routing
    def routing
      object['_routing'] || object[:_routing] || object['routing'] || object[:routing]
    end

    # @return [Hash] the document meta
    def meta
      {}
    end

    # @return [Hash] the document source
    # @abstract Override this method to return the document source
    def source
      object.reject { |key, _| META_KEYS.include?(key.to_sym) }
    end
  end
end
