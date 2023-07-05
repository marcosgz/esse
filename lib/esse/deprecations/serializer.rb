# frozen_string_literal: true

module Esse
  class Serializer < Esse::Document
    class << self
      extend Esse::Deprecations::Deprecate

      def inherited(subclass)
        warning 'Esse::Serializer', 'Esse::Document', 2023, 12
        super(subclass)
      end
    end
  end
end
