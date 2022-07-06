# frozen_string_literal: true

module Esse
  class Repository
    # https://www.elastic.co/guide/en/elasticsearch/reference/master/indices-put-mapping.html
    module ClassMethods
      # This method is only used to define mapping
      def mappings(hash = {}, &block)
        @mapping = Esse::IndexMapping.new(body: hash, paths: template_dirs, filenames: mapping_filenames)
        return unless block

        @mapping.define_singleton_method(:to_h, &block)
      end

      # This is the actually content that will be passed through the ES api
      # @return [Hash] the mapping hash
      def mapping_properties
        hash = mapping.body.dup
        hash.delete(:dynamic_templates)
        hash.key?(:properties) ? hash[:properties] : hash
      end

      def mapping_dynamic_templates
        hash = mapping.body
        hash.key?(:dynamic_templates) ? hash[:dynamic_templates] : {}
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
        Esse::IndexMapping::FILENAMES.map { |str| [document_type, str].join('_') }
      end
    end

    extend ClassMethods
  end
end
