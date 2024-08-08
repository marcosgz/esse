# frozen_string_literal: true

module Esse
  class LazyDocumentHeader
    def self.coerce_each(values)
      arr = []
      Esse::ArrayUtils.wrap(values).flatten.map do |value|
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
        new(id: value.id, type: value.type, routing: value.routing, **value.options)
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

    def valid?
      !id.nil?
    end

    def to_h
      options.merge(_id: id).tap do |hash|
        hash[:_type] = type if type
        hash[:routing] = routing if routing
      end
    end

    def to_doc(source = {})
      Document.new(self, source: source)
    end

    def eql?(other)
      self.class == other.class && id == other.id && type == other.type && routing == other.routing
    end
    alias_method :==, :eql?

    class Document < Esse::Document
      extend Forwardable

      def_delegators :object, :id, :type, :routing, :options

      attr_reader :source

      def initialize(lazy_header, source: {})
        @source = source
        super(lazy_header)
      end
    end
  end
end
