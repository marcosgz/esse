# frozen_string_literal: true

module Esse
  class Index
    module ClassMethods
      def search(*args, **kwargs, &block)
        Esse::Search::Query.new(self, *args, **kwargs, &block)
      end
    end

    extend ClassMethods
  end
end
