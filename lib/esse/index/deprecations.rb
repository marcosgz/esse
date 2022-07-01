# frozen_string_literal: true

module Esse
  class Index
    class << self
      extend Gem::Deprecate

      def define_type(type_name, *args, **kwargs, &block)
        repository(type_name, *args, **kwargs, &block)
      end
      deprecate :define_type, :repository, 2022, 7
    end
  end
end
