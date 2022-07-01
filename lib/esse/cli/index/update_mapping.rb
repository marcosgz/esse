# frozen_string_literal: true

require_relative 'base_operation'

module Esse
  module CLI
    class Index::UpdateMapping < Index::BaseOperation
      def run
        validate_options!
        indices.each do |index|
          if !index.mapping_single_type?
            index.repo_hash.values.map(&:document_type).uniq.each do |doc_type|
              index.elasticsearch.update_mapping!(type: doc_type, **options)
            end
          else
            index.elasticsearch.update_mapping!(**options)
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
