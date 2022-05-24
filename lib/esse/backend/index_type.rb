# frozen_string_literal: true

require 'forwardable'

module Esse
  module Backend
    class IndexType
      require_relative 'index_type/documents'

      extend Forwardable

      # Type delegators
      def_delegators :@index_type, :type_name, :each_serialized_batch, :serialize

      def initialize(type)
        @index_type = type
      end

      protected

      def index_name(suffix: nil)
        suffix = Hstring.new(suffix).underscore.presence
        return index_class.index_name unless suffix

        [index_class.index_name, suffix].join('_')
      end

      def index_class
        @index_type.index
      end

      def client
        index_class.cluster.client
      end

      def bulk_wait_interval
        index_class.bulk_wait_interval
      end

      # Elasticsearch::Transport was renamed to Elastic::Transport in 8.0
      # This lib should support both versions that's why we are wrapping up the transport
      # errors to local errors.
      def coerce_exception
        yield
      rescue => exception
        name = Hstring.new(exception.class.name)
        if /^Elastic(search)?::Transport::Transport::Errors/.match?(name.value) && (exception_class = ERRORS[name.demodulize.value])
          raise exception_class.new(exception.message)
        else
          raise exception
        end
      end
    end
  end
end
