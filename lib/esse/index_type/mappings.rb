# frozen_string_literal: true

module Esse
  class IndexType
    # https://www.elastic.co/guide/en/elasticsearch/reference/master/indices-put-mapping.html
    module ClassMethods
      # This method is only used to define mapping
      def mappings(hash = {}, &block)
        @mapping = Esse::IndexMapping.new(body: hash, paths: template_dirs, filenames: mapping_filenames)
        return unless block_given?

        @mapping.define_singleton_method(:to_h, &block)
      end

      # This is the actually content that will be passed through the ES api
      def mappings_hash
        hash = mapping.body
        {
          type_name => (hash.key?('properties') ? hash : { 'properties' => hash }),
        }
      end

      private

      def mapping
        @mapping ||= Esse::IndexMapping.new(paths: template_dirs, filenames: mapping_filenames)
      end

      def template_dirs
        return [] unless respond_to?(:index)

        index.template_dirs
      end

      def mapping_filenames
        Esse::IndexMapping::FILENAMES.map { |str| [type_name, str].join('_') }
      end
    end

    extend ClassMethods
  end
end
