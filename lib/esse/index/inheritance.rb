# frozen_string_literal: true

module Esse
  class Index
    module ClassMethods
      # Set this to +true+ if this is an abstract class
      attr_accessor :abstract_class

      def abstract_class?
        return @abstract_class == true if defined?(@abstract_class)

        !index_name?
      end
    end

    extend ClassMethods
  end
end
