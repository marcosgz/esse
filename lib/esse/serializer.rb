# frozen_string_literal: true

module Esse
  class Serializer
    attr_reader :object, :options

    def initialize(object, **options)
      @object = object
      @options = options
    end

    # @return [String, Number] the document ID
    # @abstract Override this method to return the document ID
    def id
      raise NotImplementedError, 'Override this method to return the document ID'
    end

    # @return [String, nil] the document type
    # @abstract Override this method to return the document type
    def type
      nil
    end

    # @return [String, nil] the document routing
    # @abstract Override this method to return the document routing
    def routing
      nil
    end

    # @return [Hash] the document meta
    # @abstract Override this method to return the document meta
    def meta
      {}
    end

    # @return [Hash] the document source
    # @abstract Override this method to return the document source
    def source
      {}
    end

    # @return [Hash] the document data
    def to_h
      source.merge(
        _id: id,
      ).tap do |hash|
        hash[:_type] = type if type
        hash[:_routing] = routing if routing
        hash.merge!(meta)
      end
    end
  end
end
