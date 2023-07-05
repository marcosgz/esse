# frozen_string_literal: true

module Esse
  module Deprecations
    class RepositoryBackendDelegator
      extend Esse::Deprecations::Deprecate

      def initialize(namespace, repo)
        @namespace = namespace
        @repo = repo
      end

      def import(**kwargs)
        warning("#{@repo}.#{@namespace}.import", "#{@repo}.import", 2023, 12)

        @repo.import(**kwargs)
      end

      def import!(**kwargs)
        warning("#{@repo}.#{@namespace}.import!", "#{@repo}.import", 2023, 12)

        @repo.import(**kwargs)
      end

      def bulk(**kwargs)
        warning("#{@repo}.#{@namespace}.bulk", "#{@repo.index}.bulk", 2023, 12)

        @repo.index.bulk(**kwargs)
      end

      def bulk!(**kwargs)
        warning("#{@repo}.#{@namespace}.bulk!", "#{@repo.index}.bulk", 2023, 12)

        @repo.index.bulk(**kwargs)
      end

      def index(**kwargs)
        warning("#{@repo}.#{@namespace}.index", "#{@repo.index}.index", 2023, 12)

        @repo.index.index(**kwargs)
      end

      def index!(**kwargs)
        warning("#{@repo}.#{@namespace}.index!", "#{@repo.index}.index", 2023, 12)

        @repo.index.index(**kwargs)
      end

      def index_document(*args, **kwargs)
        warning("#{@repo}.#{@namespace}.index_document", "#{@repo.index}.index", 2023, 12)

        @repo.index.index(*args, **kwargs)
      end

      def update!(**kwargs)
        warning("#{@repo}.#{@namespace}.update!", "#{@repo.index}.update", 2023, 12)

        @repo.index.update(**kwargs)
      end

      def update(**kwargs)
        warning("#{@repo}.#{@namespace}.update", "#{@repo.index}.update", 2023, 12)

        @repo.index.update(**kwargs)
      end

      def delete!(**kwargs)
        warning("#{@repo}.#{@namespace}.delete!", "#{@repo.index}.delete", 2023, 12)

        @repo.index.delete(**kwargs)
      end

      def delete(**kwargs)
        warning("#{@repo}.#{@namespace}.delete", "#{@repo.index}.delete", 2023, 12)

        @repo.index.delete(**kwargs)
      end

      def delete_document(*args, **kwargs)
        warning("#{@repo}.#{@namespace}.delete_document", "#{@repo.index}.delete", 2023, 12)

        @repo.index.delete(*args, **kwargs)
      end

      def count(**kwargs)
        warning("#{@repo}.#{@namespace}.count", "#{@repo.index}.count", 2023, 12)

        @repo.index.count(**kwargs)
      end

      def exist?(**kwargs)
        warning("#{@repo}.#{@namespace}.exist?", "#{@repo.index}.exist?", 2023, 12)

        @repo.index.exist?(**kwargs)
      end

      def find!(**kwargs)
        warning("#{@repo}.#{@namespace}.find!", "#{@repo.index}.get", 2023, 12)

        @repo.index.get(**kwargs)
      end

      def find(**kwargs)
        warning("#{@repo}.#{@namespace}.find", "#{@repo.index}.get", 2023, 12)

        @repo.index.get(**kwargs)
      end
    end
  end
end
