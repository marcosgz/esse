# frozen_string_literal: true

module Esse
  class Repository
    class << self
      extend Esse::Deprecations::Deprecate

      def type_name
        repo_name
      end
      deprecate :type_name, :repo_type, 2023, 12

      def mappings(*args, &block)
        warning("#{self}.mappings", "#{index}.mappings", 2023, 12)

        index.mappings(*args, &block)
      end

      def serializer(*args, **kwargs, &block)
        warning("#{self}.serializer", "#{self}.document", 2023, 12)

        document(*args, **kwargs, &block)
      end

      def elasticsearch
        Esse::Deprecations::RepositoryBackendDelegator.new(:elasticsearch, self)
      end

      def backend
        Esse::Deprecations::RepositoryBackendDelegator.new(:backend, self)
      end
    end
  end
end
