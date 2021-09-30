# frozen_string_literal: true

module Esse
  module Events
    # Event bus
    #
    # An event bus stores listeners (callbacks) and events
    #
    # @api private
    class Bus
      # @return [Hash] A hash with events registered within a bus
      attr_reader :events

      # @return [Hash] A hash with event listeners registered within a bus
      attr_reader :listeners

      # Initialize a new event bus
      #
      # @param [Hash] events A hash with events
      # @param [Hash] listeners A hash with listeners
      #
      # @api private
      # @idea
      #   Hash is thread-safe in practice because CRuby runs
      #   threads one at a time and does not do context
      #   switching during the execution of C functions
      #   However, in case of jRuby or other ruby interpreters,
      #   this assumption may not be true. In that case, we should
      #   use a different data structure. I think we should use
      #   a Concurrent::Hash or Concurrent::Map object from
      #   concurrent-ruby
      # @see https://github.com/ruby-concurrency/concurrent-ruby
      def initialize(events: {}, listeners: Hash.new { |h, k| h[k] = [] })
        @listeners = listeners
        @events = events
      end

      # @api private
      def publish(event_id, payload)
        process(event_id, payload) do |event, listener|
          listener.call(event)
        end
      end

      # @api private
      def attach(listener)
        events.each do |id, event|
          method_name = event.listener_method
          next unless listener.respond_to?(method_name)

          listeners[id] << listener.method(method_name)
        end
      end

      # @api private
      def detach(listener)
        listeners.each do |id, arr|
          arr.each do |func|
            listeners[id].delete(func) if func.receiver == listener
          end
        end
      end

      # @api private
      def subscribe(event_id, &block)
        listeners[event_id] << block
        self
      end

      # @api private
      def subscribed?(listener)
        listeners.values.any? { |value| value.any? { |func| func == listener } } || (
          methods = events.values.map(&:listener_method).select(&listener.method(:respond_to?)).map(&listener.method(:method))
          methods && listeners.values.any? { |value| (methods & value).size > 0 }
        )
      end

      # @api private
      def can_handle?(object_or_event_id)
        case object_or_event_id
        when String, Symbol
          events.key?(object_or_event_id)
        else
          events
            .values
            .map(&:listener_method)
            .any?(&object_or_event_id.method(:respond_to?))
        end
      end

      protected

      # @api private
      def process(event_id, payload)
        listeners[event_id].each do |listener|
          event = events[event_id].payload(payload)

          yield(event, listener)
        end
      end
    end
  end
end
