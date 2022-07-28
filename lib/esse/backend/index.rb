# frozen_string_literal: true

require 'forwardable'

module Esse
  module Backend
    class Index
      require_relative 'index/aliases'
      require_relative 'index/create'
      require_relative 'index/delete'
      require_relative 'index/existance'
      require_relative 'index/update'
      require_relative 'index/refresh'
      require_relative 'index/reset'
      require_relative 'index/documents'
      require_relative 'index/open'
      require_relative 'index/close'

      extend Forwardable

      NAMING = %i[index_version].freeze
      DEFINITION = %i[settings_hash mappings_hash].freeze
      DOCUMENTS = %i[each_serialized_batch].freeze

      def_delegators :@index, :index_name, :cluster, :repo_hash, :bulk_wait_interval, *(NAMING + DEFINITION + DOCUMENTS)
      def_delegators :cluster, :document_type?, :client

      def initialize(index)
        @index = index
      end

      protected

      def build_real_index_name(suffix = nil)
        suffix = Hstring.new(suffix).underscore.presence || index_version || Esse.timestamp

        index_name(suffix: suffix)
      end

      # Elasticsearch::Transport was renamed to Elastic::Transport in 8.0
      # This lib should support both versions that's why we are wrapping up the transport
      # errors to local errors.
      def coerce_exception
        yield
      rescue => exception
        name = Hstring.new(exception.class.name)
        if /^(Elasticsearch|Elastic|OpenSearch)?::Transport::Transport::Errors/.match?(name.value) && \
            (exception_class = ERRORS[name.demodulize.value])
          raise exception_class.new(exception.message)
        else
          raise exception
        end
      end
    end
  end
end
