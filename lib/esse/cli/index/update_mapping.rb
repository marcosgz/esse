# frozen_string_literal: true

require_relative 'base_operation'

module Esse
  module CLI
    class Index::UpdateMapping < Index::BaseOperation
      def run
        validate_options!
        indices.each do |index|
          if index.type_hash.any?
            index.type_hash.each_value do |type|
              # @idea Add update_mapping! to IndexType and use it here
              index.elasticsearch.update_mapping!(type: type.type_name, **options)
              print_success 'Index %<name>s#%<type>s mappings successfuly updated',
                type: type.type_name,
                name: index.elasticsearch.send(:index_name, suffix: options[:suffix]) # @todo use pub/sub api to get real index name
            end
          else
            index.elasticsearch.update_mapping!(**options)
            print_success 'Index %<name>s mappings successfuly updated',
              name: index.elasticsearch.send(:index_name, suffix: options[:suffix]) # @todo use pub/sub api to get real index name
          end
        end
      end

      private

      def options
        @options.slice(*@options.keys - CLI_IGNORE_OPTS)
      end

      def validate_options!
        validate_indices_option!
      end
    end
  end
end
