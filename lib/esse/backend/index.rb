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

      def_delegators :@index, :type_hash, *(NAMING + DEFINITION)

      def initialize(index)
        @index = index
      end

      protected

      def index_name(suffix: nil)
        suffix = Hstring.new(suffix).underscore.presence
        return @index.index_name unless suffix

        [@index.index_name, suffix].join('_')
      end

      def build_real_index_name(suffix = nil)
        suffix = Hstring.new(suffix).underscore.presence || index_version || Esse.timestamp

        index_name(suffix: suffix)
      end

      def client
        cluster.client
      end

      def cluster
        @index.cluster
      end
    end
  end
end
