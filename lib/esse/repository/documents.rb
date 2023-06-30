# frozen_string_literal: true

module Esse
  class Repository
    module ClassMethods
      def import(**kwargs)
        index.import(repo_type, **kwargs)
      end

      def import!(**kwargs)
        index.import!(repo_type, **kwargs)
      end

      protected

      # @TODO change document_type to repo_type globally
      def repo_type
        document_type
      end
    end

    extend ClassMethods
  end
end
