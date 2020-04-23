# frozen_string_literal: true

module Esse
  class Index
    module ClassMethods
      # Set this to +true+ if this is an abstract class
      attr_accessor :abstract_class

      def abstract_class?
        !!defined?(@abstract_class) && @abstract_class == true # rubocop:disable Style/DoubleNegation
      end
    end

    extend ClassMethods
  end
end
