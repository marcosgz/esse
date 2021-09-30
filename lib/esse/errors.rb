# frozen_string_literal: true

module Esse
  class Error < StandardError
  end

  module Events
    class UnregisteredEventError < ::Esse::Error
      def initialize(object_or_event_id)
        case object_or_event_id
        when String, Symbol
          super("You are trying to publish an unregistered event: `#{object_or_event_id}`")
        else
          super('You are trying to publish an unregistered event')
        end
      end
    end

    class InvalidSubscriberError < ::Esse::Error
      # @api private
      def initialize(object_or_event_id)
        case object_or_event_id
        when String, Symbol
          super("you are trying to subscribe to an event: `#{object_or_event_id}` that has not been registered")
        else
          super('you try use subscriber object that will never be executed')
        end
      end
    end
  end

  module CLI
    class Error < ::Esse::Error
      def initialize(msg = nil, **message_attributes)
        if message_attributes.any?
          msg = format(msg, **message_attributes)
        end
        super(msg)
      end
    end

    class InvalidOption < Error
    end
  end
end
