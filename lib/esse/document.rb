# frozen_string_literal: true

module Esse
  class Document
    MUTATIONS_FALLBACK = {}.freeze

    attr_reader :object, :options

    def initialize(object, **options)
      @object = object
      @options = options.freeze
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

    # @TODO allow import, index, bulk to accept a suffix to tell which index to use
    # def index_suffix
    #   nil
    # end

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
      mutated_source.merge(
        _id: id,
      ).tap do |hash|
        hash[:_type] = type if type
        hash[:_routing] = routing if routing
        hash.merge!(meta)
      end
    end

    def to_bulk(data: true, operation: nil)
      doc_header.tap do |h|
        if data && operation == :update
          h[:data] = { doc: mutated_source }
        elsif data
          h[:data] = mutated_source
        end
        h.merge!(meta)
      end
    end

    def ignore_on_index?
      id.nil?
    end

    def ignore_on_delete?
      id.nil?
    end

    def eql?(other, match_lazy_doc_header: false)
      if match_lazy_doc_header
        other.eql?(self)
      else
        other.is_a?(Esse::Document) && (
          id.to_s == other.id.to_s && type == other.type && routing == other.routing && meta == other.meta
        )
      end
    end
    alias_method :==, :eql?

    def doc_header
      { _id: id }.tap do |h|
        h[:_type] = type if type
        h[:routing] = routing if routing?
      end
    end

    def document_for_partial_update(source)
      DocumentForPartialUpdate.new(self, source: source)
    end

    def inspect
      attributes = %i[id routing source].map do |attr|
        value = send(attr)
        next unless value
        "#{attr}: #{value.inspect}"
      rescue
        nil
      end.compact.join(', ')
      attributes << " mutations: #{@__mutations__.inspect}" if @__mutations__
      "#<#{self.class.name || 'Esse::Document'} #{attributes}>"
    end

    def mutate(key)
      @__mutations__ ||= {}
      @__mutations__[key] = yield
      instance_variable_set(:@__mutated_source__, nil)
    end

    def mutations
      @__mutations__ || MUTATIONS_FALLBACK
    end

    def mutated_source
      return source unless @__mutations__

      @__mutated_source__ ||= source.merge(@__mutations__)
    end
  end
end
