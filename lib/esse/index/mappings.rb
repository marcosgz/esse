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
        mapps = mapping.body.dup
        mapps = mapps[Esse::MAPPING_ROOT_KEY] if mapps.key?(Esse::MAPPING_ROOT_KEY)
        dynamic_template = DynamicTemplate.new(mapps.delete(:dynamic_templates))

        properties = mapps.key?(:properties) ? mapps[:properties] : mapps
        if mapping_single_type? || cluster.engine.mapping_default_type
          # Merge Mappings and Dynamic Templates from Repo templates
          repo_hash.values.each do |klass|
            dynamic_template.merge!(klass.mapping_dynamic_templates)
            properties = HashUtils.deep_merge(properties, klass.mapping_properties)
          end
        else
          values = repo_hash.values.each_with_object({}) do |klass, memo|
            hash = {}
            if (props = HashUtils.deep_merge(properties, klass.mapping_properties)).any?
              hash[:properties] = props
            end
            if (dup_tmpl = dynamic_template.dup) && dup_tmpl.merge!(klass.mapping_dynamic_templates).any?
              hash[:dynamic_templates] = dup_tmpl.to_a
            end
            memo[klass.document_type.to_sym] = hash
          end

          return { Esse::MAPPING_ROOT_KEY => values }
        end

        values = {}
        values[:properties] = properties if properties.any?
        values[:dynamic_templates] = dynamic_template.to_a if dynamic_template.any?

        values = if (doc_type = cluster.engine.mapping_default_type)
          { Esse::MAPPING_ROOT_KEY => { doc_type => values } }
        else
          { Esse::MAPPING_ROOT_KEY => values }
        end
      end

      private

      def mapping
        @mapping ||= Esse::IndexMapping.new(paths: template_dirs)
      end
    end

    extend ClassMethods
  end
end
