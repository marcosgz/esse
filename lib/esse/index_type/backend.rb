# frozen_string_literal: true

module Esse
  class IndexType
    module ClassMethods
      def elasticsearch
        Esse::Backend::IndexType.new(self)
      end
      alias_method :backend, :elasticsearch
    end

    extend ClassMethods
  end
end
