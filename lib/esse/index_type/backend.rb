# frozen_string_literal: true

module Esse
  class IndexType
    module ClassMethods
      def backend
        Esse::Backend::IndexType.new(self)
      end
    end

    extend ClassMethods
  end
end
