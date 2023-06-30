# frozen_string_literal: true

module Esse
  class Index
    class << self
      extend Gem::Deprecate

      def define_type(name, *args, **kwargs, &block)
        repository(name, *args, **kwargs, &block)
      end
      deprecate :define_type, :repository, 2023, 12

      def type_hash
        repo_hash
      end
      deprecate :type_hash, :repo_hash, 2023, 12

      def elasticsearch
        Esse::Deprecations::IndexBackendDelegator.new(self)
      end
      alias_method :backend, :elasticsearch
      deprecate :elasticsearch, 'Esse::Index.<elasticsearch.method>', 2023, 12
      deprecate :backend, 'Esse::Index.<elasticsearch.method>', 2023, 12
    end
  end
end
