# frozen_string_literal: true

require 'forwardable'

module Esse
  module Backend
    class IndexType
      extend Forwardable

      # Type delegators
      def_delegators :@index_type, :type_name, :index, :serialize

      def initialize(type)
        @index_type = type
      end

      def import(**kwargs)
        elasticsearch.import(doc_type, **kwargs)
      end

      def import!(**kwargs)
        elasticsearch.import!(doc_type, **kwargs)
      end

      def bulk!(**kwargs)
        elasticsearch.bulk!(**kwargs, type: doc_type)
      end

      def bulk(**kwargs)
        elasticsearch.bulk(**kwargs, type: doc_type)
      end

      def index!(**kwargs)
        elasticsearch.index!(**kwargs, type: doc_type)
      end

      def index(**kwargs)
        elasticsearch.index(**kwargs, type: doc_type)
      end

      def update!(**kwargs)
        elasticsearch.update!(**kwargs, type: doc_type)
      end

      def update(**kwargs)
        elasticsearch.update(**kwargs, type: doc_type)
      end

      def delete!(**kwargs)
        elasticsearch.delete!(**kwargs, type: doc_type)
      end

      def delete(**kwargs)
        elasticsearch.delete(**kwargs, type: doc_type)
      end

      def exist?(**kwargs)
        elasticsearch.exist?(**kwargs, type: doc_type)
      end

      def count(**kwargs)
        elasticsearch.count(**kwargs, type: doc_type)
      end

      def find!(**kwargs)
        elasticsearch.find!(**kwargs, type: doc_type)
      end

      def find(**kwargs)
        elasticsearch.find(**kwargs, type: doc_type)
      end

      protected

      def elasticsearch
        @index_type.index.elasticsearch
      end

      def doc_type
        type_name.to_sym
      end
    end
  end
end
