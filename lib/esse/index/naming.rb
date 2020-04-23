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

      def uname
        Hstring.new(name).underscore.presence
      end

      def dirname
        filename = File.expand_path(__FILE__)
        strip_ext_re = Regexp.new("#{Regexp.escape(File.extname(filename))}$")
        filename.sub(strip_ext_re, '')
      end

      def template_dirs
        TEMPLATE_DIRS.map { |term| format(term, dirname: dirname) }
      end

      protected

      def index_prefixed_name(value)
        return if value == '' || value.nil?
        return value.to_s unless Esse.config.index_prefix

        [Esse.config.index_prefix, value].join('_')
      end

      def normalized_name
        Hstring.new(name).demodulize.underscore.sub(/_(index)$/, '')
      end
    end

    extend ClassMethods
  end
end
