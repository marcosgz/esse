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
      require_relative 'index/documents'

      extend Forwardable

      NAMING = %i[index_name index_version].freeze
      DEFINITION = %i[settings_hash mappings_hash].freeze

      def_delegators :@index, *(NAMING + DEFINITION)

      def initialize(index)
        @index = index
      end

      protected

      def real_index_name(suffix = nil)
        suffix = Hstring.new(suffix).underscore.presence || index_version || Esse.timestamp
        [index_name, suffix].compact.join('_')
      end

      def client
        @index.elasticsearch_client
      end
    end
  end
end
