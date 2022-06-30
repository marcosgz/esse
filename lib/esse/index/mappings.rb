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
        @mapping = Esse::IndexMapping.new(body: hash, paths: template_dirs)
        return unless block

        @mapping.define_singleton_method(:to_h, &block)
      end

      # This is the actually content that will be passed through the ES api
      def mappings_hash
        props = mapping.body.dup
        props = props[Esse::MAPPING_ROOT_KEY] if props.key?(Esse::MAPPING_ROOT_KEY)
        props = props['properties'] if props.key?('properties')
        if mapping_single_type? || cluster.engine.mapping_default_type
          type_hash.values.each do |type|
            props = HashUtils.deep_merge(props, type.mapping_properties)
          end
        else
          props = type_hash.values.each_with_object({}) do |type, memo|
            memo[type.type_name.to_s] = {
              'properties' => HashUtils.deep_merge(props, type.mapping_properties)
            }
          end
        end
        values = if (type_name = cluster.engine.mapping_default_type)
          { type_name => { 'properties' => props } }
        elsif mapping_single_type?
          { 'properties' => props }
        else
          props
        end
        { Esse::MAPPING_ROOT_KEY => values }
      end

      private

      def mapping
        @mapping ||= Esse::IndexMapping.new(paths: template_dirs)
      end
    end

    extend ClassMethods
  end
end
