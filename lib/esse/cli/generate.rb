# frozen_string_literal: true

require 'thor'
require 'ostruct'
require_relative 'base'

module Esse
  module CLI
    class Generate < Base
      NAMESPACE_PATTERN_RE = %r{:|/|\\}i.freeze

      def self.source_root
        File.dirname(__FILE__)
      end

      desc 'index NAME *TYPES', 'Creates a new index'
      option :settings, type: :boolean, default: false, desc: 'Generate settings'
      option :mappings, type: :boolean, default: false, desc: 'Generate mappings'
      option :serializers, type: :boolean, default: false, desc: 'Generate serializers'
      option :collections, type: :boolean, default: false, desc: 'Generate collections'
      option :active_record, type: :boolean, default: false, desc: 'Generate ActiveRecord models'
      def index(name, *types)
        ns_path = name.split(NAMESPACE_PATTERN_RE).tap(&:pop)
        @index_name = Hstring.new(name.to_s).modulize.sub(/Index$/, '') + 'Index'
        @index_name = Hstring.new(@index_name)
        @types = types.map { |type| Hstring.new(type) }
        @base_class = base_index_class(*ns_path)
        @cli_options = options

        base_dir = Esse.config.indices_directory.join(*ns_path)
        index_name = @index_name.demodulize.underscore.to_s
        template(
          'templates/index.rb.erb',
          base_dir.join("#{index_name}.rb"),
        )

        if options[:settings]
          copy_file(
            'templates/settings.json',
            base_dir.join(index_name, 'templates', "settings.json"),
          )
        end

        if @types.empty?
          if options[:mappings]
            copy_file(
              'templates/mapping.json',
              base_dir.join(index_name, 'templates', "mapping.json"),
            )
          end
          if options[:serializers]
            template(
              'templates/serializer.rb.erb',
              base_dir.join(index_name, 'serializers', "serializer.rb"),
            )
          end
          if options[:collections] && !options[:active_record]
            template(
              'templates/collection.rb.erb',
              base_dir.join(index_name, 'collections', "collection.rb"),
            )
          end
        end

        @types.each do |type|
          @type = Hstring.new(type).underscore
          if options[:mappings]
            copy_file(
              'templates/mapping.json',
              base_dir.join(index_name, 'templates', "#{@type}_mapping.json"),
            )
          end
          if options[:serializers]
            template(
              'templates/serializer.rb.erb',
              base_dir.join(index_name, 'serializers', "#{@type}_serializer.rb"),
            )
          end
          if options[:collections] && !options[:active_record]
            template(
              'templates/collection.rb.erb',
              base_dir.join(index_name, 'collections', "#{@type}_collection.rb"),
            )
          end
        end
      end

      protected

      def base_index_class(*ns)
        return 'ApplicationIndex' if Esse.config.indices_directory.join(*ns, 'application_index.rb').exist?

        'Esse::Index'
      end
    end
  end
end
