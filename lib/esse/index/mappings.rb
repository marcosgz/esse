# frozen_string_literal: true

# The es 7.6 deprecate the mapping definition under the type level. That's why we have option
# to define mappings under both Type and Index. If the index mapping is defined. All the Type
# mapping will be ignored.
# Source: https://www.elastic.co/guide/en/elasticsearch/reference/7.6/removal-of-types.html
module Esse
  class Index
    module ClassMethods
      # This method is only used to define mapping
      def mappings(hash = {}, &block)
        @mapping = Esse::IndexMapping.new(body: hash, paths: template_dirs, globals: -> { cluster.mappings })
        return unless block

        @mapping.define_singleton_method(:to_h, &block)
      end

      def mappings_hash
        hash = mapping.body
        { Esse::MAPPING_ROOT_KEY => (hash.key?(Esse::MAPPING_ROOT_KEY) ? hash[Esse::MAPPING_ROOT_KEY] : hash) }
      end

      private

      def mapping
        @mapping ||= Esse::IndexMapping.new(paths: template_dirs, globals: -> { cluster.mappings })
      end
    end

    extend ClassMethods
  end
end
