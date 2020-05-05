# frozen_string_literal: true

module Esse
  class Index
    module ClassMethods
      TEMPLATE_DIRS = [
        '%<dirname>s/templates',
        '%<dirname>s'
      ].freeze

      def index_name=(value)
        @index_name = index_prefixed_name(value)
      end

      def index_name
        @index_name || index_prefixed_name(normalized_name)
      end

      def index_name?
        !index_name.nil?
      end

      def index_version=(value)
        @index_version = Hstring.new(value.to_s).underscore.presence
      end

      def index_version
        @index_version
      end

      def uname
        Hstring.new(name).underscore.presence
      end

      def index_directory
        return unless uname
        return if uname == 'Esse::Index'

        Esse.config.indices_directory.join(uname).to_s
      end

      def template_dirs
        return [] unless index_directory

        TEMPLATE_DIRS.map { |term| format(term, dirname: index_directory) }
      end

      protected

      def index_prefixed_name(value)
        return if value == '' || value.nil?
        return value.to_s unless cluster.index_prefix

        [cluster.index_prefix, value].join('_')
      end

      def normalized_name
        Hstring.new(name).demodulize.underscore.sub(/_(index)$/, '')
      end
    end

    extend ClassMethods
  end
end
