# frozen_string_literal: true

module Esse
  class LazyDocumentHeader
    ACCEPTABLE_CLASSES = [Esse::LazyDocumentHeader, Esse::Document].freeze
    ACCEPTABLE_DOC_TYPES = [nil, '_doc', 'doc'].freeze

    def self.coerce_each(values)
      values = Esse::ArrayUtils.wrap(values)
      return values if values.all? do |value|
        ACCEPTABLE_CLASSES.any? { |klass| value.is_a?(klass) }
      end

      arr = []
      values.flatten.map do |value|
        instance = coerce(value)
        arr << instance if instance && !instance.id.nil?
      end
      arr
    end

    def self.coerce(value)
      return unless value

      if value.is_a?(Esse::LazyDocumentHeader)
        value
      elsif value.is_a?(Esse::Document)
        value
      elsif value.is_a?(Hash)
        resp = value.transform_keys do |key|
          case key
          when :_id, :id, '_id', 'id'
            :id
          when :_routing, :routing, '_routing', 'routing'
            :routing
          when :_type, :type, '_type', 'type'
            :type
          else
            key.to_sym
          end
        end
        resp[:id] ||= nil
        new(**resp)
      elsif String === value || Integer === value
        new(id: value)
      end
    end

    attr_reader :id, :type, :routing, :options

    def initialize(id:, type: nil, routing: nil, **extra_attributes)
      @id = id
      @type = type
      @routing = routing
      @options = extra_attributes.freeze
    end

    def to_h
      options.merge(_id: id).tap do |hash|
        hash[:_type] = type if type
        hash[:routing] = routing if routing
      end
    end

    def document_for_partial_update(source)
      Esse::DocumentForPartialUpdate.new(self, source: source)
    end

    def doc_header
      { _id: id }.tap do |hash|
        hash[:_type] = type if type
        hash[:routing] = routing if routing
      end
    end

    def eql?(other, **)
      ACCEPTABLE_CLASSES.any? { |klass| other.is_a?(klass) } &&
        id.to_s == other.id.to_s &&
        routing == other.routing &&
        ((ACCEPTABLE_DOC_TYPES.include?(type) && ACCEPTABLE_DOC_TYPES.include?(other.type)) || type == other.type)
    end
    alias_method :==, :eql?
  end
end

