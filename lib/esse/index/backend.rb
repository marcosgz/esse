# frozen_string_literal: true

module Esse
  class Index
    module ClassMethods
      def elasticsearch
        Esse::Backend::Index.new(self)
      end
      alias backend elasticsearch
    end

    extend ClassMethods
  end
end
