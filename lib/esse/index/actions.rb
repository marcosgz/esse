# frozen_string_literal: true

module Esse
  class Index
    module ClassMethods
      def action(name, options = {}, &block); end
    end

    extend ClassMethods
  end
end
