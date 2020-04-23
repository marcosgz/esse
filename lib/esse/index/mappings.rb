# frozen_string_literal: true

# The es 7.6 deprecate the mapping definition under the type level. That's why we have option
# to define mappings under both Type and Index. If the index mapping is defined. All the Type
# mapping will be ignored.
# Source: https://www.elastic.co/guide/en/elasticsearch/reference/7.6/removal-of-types.html
module Esse
  class Index
    module ClassMethods
      MAPPING_ROOT_KEY = 'mappings'

      # This is the actually content that will be passed through the ES api
      def mappings_hash
        { MAPPING_ROOT_KEY => (index_mapping || type_mapping) }
      end

      # This method is only used to define mapping
      def mappings(hash = {}, &block)
        @mapping = Esse::IndexMapping.new(body: hash, paths: template_dirs)
        return unless block_given?

        @mapping.define_singleton_method(:as_json, &block)
      end

      private

      def mapping
        @mapping ||= Esse::IndexMapping.new(paths: template_dirs)
      end

      def index_mapping
        return if mapping.empty?

        hash = mapping.body
        hash.key?(MAPPING_ROOT_KEY) ? hash[MAPPING_ROOT_KEY] : hash
      end

      def type_mapping
        return {} if type_hash.empty?

        type_hash.values.map(&:mappings_hash).reduce(&:merge)
      end
    end

    extend ClassMethods
  end
end
