# frozen_string_literal: true

module Esse
  class Index
    module ClassMethods
      def descendants # :nodoc:
        descendants = []
        ObjectSpace.each_object(singleton_class) do |k|
          descendants.unshift k unless k == self
        end
        descendants.uniq
      end
    end

    extend ClassMethods
  end
end
