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
      option :documents, type: :boolean, default: false, desc: 'Generate documents'
      option :collections, type: :boolean, default: false, desc: 'Generate collections'
      option :active_record, type: :boolean, default: false, desc: 'Generate ActiveRecord models'
      option :cluster_id, type: :string, desc: 'Elasticsearch cluster ID'
      def index(name, *types)
        ns_path = name.split(NAMESPACE_PATTERN_RE).tap(&:pop)
        @index_name = Hstring.new(name.to_s).modulize.sub(/Index$/, '') + 'Index'
        @index_name = Hstring.new(@index_name)
        @types = types.map { |type| Hstring.new(type) }
        @base_class = base_index_class(*ns_path)
        if options[:cluster_id]
          @base_class += format('(:%s)', options[:cluster_id])
        end
        @cli_options = options

        base_dir = Esse.config.indices_directory.join(*ns_path.map { |n| Hstring.new(n).underscore.to_s })
        index_name = @index_name.demodulize.underscore.to_s
        template(
          'templates/index.rb.erb',
          base_dir.join("#{index_name}.rb"),
        )

        if options[:settings]
          copy_file(
            'templates/settings.json',
            base_dir.join(index_name, 'templates', 'settings.json'),
          )
        end

        if options[:mappings]
          copy_file(
            'templates/mappings.json',
            base_dir.join(index_name, 'templates', 'mappings.json'),
          )
        end

        if @types.empty?
          if options[:documents]
            template(
              'templates/document.rb.erb',
              base_dir.join(index_name, 'documents', 'document.rb'),
            )
          end
          if options[:collections] && !options[:active_record]
            template(
              'templates/collection.rb.erb',
              base_dir.join(index_name, 'collections', 'collection.rb'),
            )
          end
        end

        @types.each do |type|
          @type = Hstring.new(type).underscore

          if options[:documents]
            template(
              'templates/document.rb.erb',
              base_dir.join(index_name, 'documents', "#{@type}_document.rb"),
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
