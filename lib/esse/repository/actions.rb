# frozen_string_literal: true

module Esse
  class Repository
    module ClassMethods
      def action(name, options = {}, &block)
      end
    end

    extend ClassMethods
  end
end
