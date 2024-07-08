# frozen_string_literal: true

module Esse
  class LazyDocumentHeader
    def self.coerce_each(values)
      arr = []
      Array(values).map do |value|
        instance = coerce(value)
        arr << instance if instance&.valid?
      end
      arr
    end

    def self.coerce(value)
      return unless value

      if value.is_a?(Esse::LazyDocumentHeader)
        value
      elsif value.is_a?(Esse::Document)
        new(value.doc_header)
      elsif value.is_a?(Hash)
        resp = value.transform_keys do |key|
          case key
          when :_id, :id, '_id', 'id'
            :_id
          when :_routing, :routing, '_routing', 'routing'
            :_routing
          when :_type, :type, '_type', 'type'
            :_type
          else
            key.to_sym
          end
        end
        new(resp)
      elsif String === value || Integer === value
        new(_id: value)
      end
    end

    def initialize(attributes)
      @attributes = attributes
    end

    def valid?
      !@attributes[:_id].nil?
    end

    def to_h
      @attributes
    end

    def id
      @attributes.fetch(:_id)
    end

    def type
      @attributes[:_type]
    end

    def routing
      @attributes[:_routing]
    end
  end
end
