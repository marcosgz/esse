# frozen_string_literal: true

module Esse
  class Error < StandardError
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
