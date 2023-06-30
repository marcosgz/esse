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

    # @return [Boolean] whether the document has type
    def type?
      !type.nil?
    end

    # @return [String, nil] the document routing
    # @abstract Override this method to return the document routing
    def routing
      nil
    end

    # @return [Boolean] whether the document has routing
    def routing?
      !routing.nil?
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

    def to_bulk(data: true)
      { _id: id }.tap do |h|
        h[:data] = source&.to_h if data
        h[:_type] = type if type
        h[:routing] = routing if routing?
        h.merge!(meta)
      end
    end

    def ignore_on_index?
      id.nil?
    end

    def ignore_on_delete?
      id.nil?
    end

    def ==(other)
      other.is_a?(self.class) && (
        id == other.id && type == other.type && routing == other.routing && meta == other.meta && source == other.source
      )
    end
  end
end
