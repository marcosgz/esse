# frozen_string_literal: true

require 'forwardable'

module Esse
  module Backend
    # @todo This class is no longer used. We can remove it in the next major
    # @see lib/esse/deprecations/index_backend.rb
    class Index
      def initialize(index)
        @index = index
      end
    end
  end
end
