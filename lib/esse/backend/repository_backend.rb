# frozen_string_literal: true

require 'forwardable'

module Esse
  module Backend
    class RepositoryBackend
      extend Forwardable

      # Type delegators
      def_delegators :@repo, :document_type, :index, :serialize

      def initialize(repo)
        @repo = repo
      end

      def import(**kwargs)
        elasticsearch.import(document_type, **kwargs)
      end

      def import!(**kwargs)
        elasticsearch.import!(document_type, **kwargs)
      end

      def bulk!(**kwargs)
        elasticsearch.bulk!(**kwargs, type: document_type)
      end

      def bulk(**kwargs)
        elasticsearch.bulk(**kwargs, type: document_type)
      end

      def index!(**kwargs)
        elasticsearch.index!(**kwargs, type: document_type)
      end

      def index(**kwargs)
        elasticsearch.index(**kwargs, type: document_type)
      end

      # @param [Esse::Serializer] document A document instance
      def index_document(document, **kwargs)
        return unless document.is_a?(Esse::Serializer)
        return if document.ignore_on_index?
        return unless document.id

        kwargs[:id] = document.id
        kwargs[:routing] = document.routing if document.routing
        kwargs[:type] = document.type || document_type
        kwargs[:body] = document.source
        elasticsearch.index(**kwargs)
      end

      def update!(**kwargs)
        elasticsearch.update!(**kwargs, type: document_type)
      end

      def update(**kwargs)
        elasticsearch.update(**kwargs, type: document_type)
      end

      def delete!(**kwargs)
        elasticsearch.delete!(**kwargs, type: document_type)
      end

      def delete(**kwargs)
        elasticsearch.delete(**kwargs, type: document_type)
      end

      # @param [Esse::Serializer] document A document instance
      def delete_document(document, **kwargs)
        return unless document.is_a?(Esse::Serializer)
        return if document.ignore_on_delete?
        return unless document.id

        kwargs[:id] = document.id
        kwargs[:routing] = document.routing if document.routing
        kwargs[:type] = document.type || document_type
        elasticsearch.delete(**kwargs)
      end

      def exist?(**kwargs)
        elasticsearch.exist?(**kwargs, type: document_type)
      end

      def count(**kwargs)
        elasticsearch.count(**kwargs, type: document_type)
      end

      def find!(**kwargs)
        elasticsearch.find!(**kwargs, type: document_type)
      end

      def find(**kwargs)
        elasticsearch.find(**kwargs, type: document_type)
      end

      protected

      def elasticsearch
        @repo.index.elasticsearch
      end
    end
  end
end
