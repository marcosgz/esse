# frozen_string_literal: true

module Esse
  class Index
    class << self
      extend Gem::Deprecate

      def define_type(name, *args, **kwargs, &block)
        repository(name, *args, **kwargs, &block)
      end
      deprecate :define_type, :repository, 2022, 7

      def type_hash
        repo_hash
      end
      deprecate :type_hash, :repo_hash, 2022, 7
    end
  end
end
