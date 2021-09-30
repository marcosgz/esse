# frozen_string_literal: true

module Esse
  module Events
    class Event
      attr_reader :id

      # Initialize a new event
      #
      # @param [Symbol, String] id The event identifier
      # @param [Hash] payload
      #
      # @return [Event]
      #
      # @api private
      def initialize(id, payload = {})
        @id = id
        @payload = payload
      end

      # Get data from the payload
      #
      # @param [String,Symbol] name
      #
      # @api public
      def [](name)
        @payload.fetch(name)
      end

      # Coerce an event to a hash
      #
      # @return [Hash]
      #
      # @api public
      def to_h
        @payload
      end
      alias_method :to_hash, :to_h

      # Get or set a payload
      #
      # @overload
      #   @return [Hash] payload
      #
      # @overload payload(data)
      #   @param [Hash] data A new payload
      #   @return [Event] A copy of the event with the provided payload
      #
      # @api public
      def payload(data = nil)
        if data
          self.class.new(id, @payload.merge(data))
        else
          @payload
        end
      end

      # @api private
      def listener_method
        @listener_method ||= Hstring.new("on_#{id}").underscore.to_sym
      end
    end
  end
end
