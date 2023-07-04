# frozen_string_literal: true

module Esse
  class Index
    class << self
      extend Esse::Deprecations::Deprecate

      def define_type(name, *args, **kwargs, &block)
        repository(name, *args, **kwargs, &block)
      end
      deprecate :define_type, :repository, 2023, 12

      def type_hash
        repo_hash
      end
      deprecate :type_hash, :repo_hash, 2023, 12

      def index_version
        index_suffix
      end
      deprecate :index_version, :index_suffix, 2023, 12

      def index_version=(value)
        self.index_suffix = value
      end
      deprecate :index_version=, :index_suffix=, 2023, 12

      def elasticsearch
        Esse::Deprecations::IndexBackendDelegator.new(:elasticsearch, self)
      end

      def backend
        Esse::Deprecations::IndexBackendDelegator.new(:backend, self)
      end
    end
  end
end
