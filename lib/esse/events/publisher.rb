# frozen_string_literal: true

require_relative 'event'
require_relative 'bus'

module Esse
  module Events
    module Publisher
      def self.included(klass)
        klass.extend(ClassMethods)
      end

      # Class interface for publishers
      #
      # @api public
      module ClassMethods
        # Register a new event type
        #
        # @param [Symbol,String] event_id The event identifier
        # @param [Hash] payload Optional default payload
        #
        # @return [self]
        #
        # @api public
        def register_event(event_id, payload = {})
          __bus__.events[event_id] = Event.new(event_id, payload)
          self
        end

        # Publish an event
        #
        # @param [String] event_id The event identifier
        # @param [Hash] payload An optional payload
        # @raise [Esse::Events::UnregisteredEventError] if the event is not registered
        #
        # @api public
        def publish(event_id, payload = {})
          if __bus__.can_handle?(event_id)
            __bus__.publish(event_id, payload)
            self
          else
            raise UnregisteredEventError, event_id
          end
        end

        # Publish an event with extra runtime information to the payload
        #
        # @param [String] event_id The event identifier
        # @param [Hash] payload An optional payload
        # @raise [Esse::Events::UnregisteredEventError] if the event is not registered
        #
        # @api public
        def instrument(event_id, payload = {}, &block)
          publish_event = false # ensure block is also called on error
          raise(UnregisteredEventError, event_id) unless __bus__.can_handle?(event_id)

          payload[:__started_at__] = Time.now
          block.call(payload).tap { publish_event = true }
        ensure
          if publish_event
            payload[:runtime] ||= Time.now - payload.delete(:__started_at__) if payload[:__started_at__]
            __bus__.publish(event_id, payload)
          end
        end

        # Subscribe to events.
        #
        # @param [Symbol,String,Object] object_or_event_id The event identifier or a listener object
        # @param [Hash] filter_hash An optional event filter
        #
        # @raise [Esse::Events::InvalidSubscriberError] if the subscriber is not registered
        # @return [Object] self
        #
        #
        # @api public
        def subscribe(object_or_event_id, &block)
          if __bus__.can_handle?(object_or_event_id)
            if block
              __bus__.subscribe(object_or_event_id, &block)
            else
              __bus__.attach(object_or_event_id)
            end

            self
          else
            raise InvalidSubscriberError, object_or_event_id
          end
        end

        # Unsubscribe a listener
        #
        # @param [Object] listener The listener object
        #
        # @return [self]
        #
        # @api public
        def unsubscribe(listener)
          __bus__.detach(listener)
        end

        # Return true if a given listener has been subscribed to any event
        #
        # @api public
        def subscribed?(listener)
          __bus__.subscribed?(listener)
        end

        # Internal event bus
        #
        # @return [Bus]
        #
        # @api private
        def __bus__
          @__bus__ ||= Bus.new
        end
      end
    end
  end
end
