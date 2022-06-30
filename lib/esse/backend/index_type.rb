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
        elasticsearch.import(type_name, **kwargs)
      end

      def import!(**kwargs)
        elasticsearch.import!(type_name, **kwargs)
      end

      def bulk!(**kwargs)
        elasticsearch.bulk!(**kwargs, type: type_name)
      end

      def bulk(**kwargs)
        elasticsearch.bulk(**kwargs, type: type_name)
      end

      def index!(**kwargs)
        elasticsearch.index!(**kwargs, type: type_name)
      end

      def index(**kwargs)
        elasticsearch.index(**kwargs, type: type_name)
      end

      def update!(**kwargs)
        elasticsearch.update!(**kwargs, type: type_name)
      end

      def update(**kwargs)
        elasticsearch.update(**kwargs, type: type_name)
      end

      def delete!(**kwargs)
        elasticsearch.delete!(**kwargs, type: type_name)
      end

      def delete(**kwargs)
        elasticsearch.delete(**kwargs, type: type_name)
      end

      def exist?(**kwargs)
        elasticsearch.exist?(**kwargs, type: type_name)
      end

      def count(**kwargs)
        elasticsearch.count(**kwargs, type: type_name)
      end

      def find!(**kwargs)
        elasticsearch.find!(**kwargs, type: type_name)
      end

      def find(**kwargs)
        elasticsearch.find(**kwargs, type: type_name)
      end

      protected

      def elasticsearch
        @index_type.index.elasticsearch
      end
    end
  end
end
