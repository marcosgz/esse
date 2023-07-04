# frozen_string_literal: true

require_relative 'base_operation'

module Esse
  module CLI
    class Index::UpdateMapping < Index::BaseOperation
      def run
        validate_options!
        indices.each do |index|
          if !index.mapping_single_type?
            # Elasticsearch 6.x and older have multiple types per index.
            # This gem supports multiple types per index for backward compatibility, but we recommend to update
            # your elasticsearch to a at least 7.x version and use a single type per index.
            #
            # Note that the repository name will be used as the document type.
            index.repo_hash.keys.each do |doc_type|
              index.update_mapping(type: doc_type, **options)
            end
          else
            index.update_mapping(**options)
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
