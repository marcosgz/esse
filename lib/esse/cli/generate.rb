# frozen_string_literal: true

require 'thor'
require 'ostruct'
require_relative 'base'

module Esse
  module CLI
    class Generate < Base
      NAMESPACE_PATTERN_RE = /\:|\/|\\/i

      def self.source_root
        File.dirname(__FILE__)
      end

      desc 'index NAME *TYPES', 'Creates a new index'
      def index(name, *types)
        ns_path = name.split(NAMESPACE_PATTERN_RE).tap(&:pop)
        @index_name = Hstring.new(name.to_s).modulize.sub(/Index$/, '') + 'Index'
        @types = types.map { |type| Hstring.new(type) }
        @base_class = base_index_class(*ns_path)
        template(
          'templates/index.rb.erb', 
          Esse.config.indices_directory.join(*ns_path, "#{Hstring.new(@index_name).demodulize.underscore}.rb")
        )
      end

      protected

      def base_index_class(*ns)
        return 'ApplicationIndex' if Esse.config.indices_directory.join(*ns, 'application_index.rb').exist?

        'Esse::Index'
      end
    end
  end
end
