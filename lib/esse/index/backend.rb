# frozen_string_literal: true

module Esse
  class Index
    module ClassMethods
      def backend
        Esse::Backend::Index.new(self)
      end
    end

    extend ClassMethods
  end
end
