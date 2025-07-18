# frozen_string_literal: true

require_relative 'base_operation'

module Esse
  module CLI
    class Index::UpdateLazyAttributes < Index::BaseOperation
      attr_reader :attributes

      def initialize(indices:, attributes: nil, **options)
        super(indices: indices, **options)
        @attributes = Array(attributes)
      end

      def run
        validate_options!
        indices.each do |index|
          repos = if (repo = @options[:repo])
            [index.repo(repo)]
          else
            index.repo_hash.values
          end

          repos.each do |repo|
            attrs = repo_attributes(repo)
            next unless attrs.any?

            repo.send(:each_batch_ids, **context_options) do |ids|
              attrs.each do |attribute|
                repo.update_documents_attribute(attribute, ids, bulk_options)
              end
            end
          end
        end
      end

      private

      def bulk_options
        @bulk_options ||= (@options[:bulk_options] || {}).transform_values do |value|
          value.is_a?(String) ? Hstring.new(value).coerce_type : value
        end
      end

      def context_options
        @context_options ||= (@options[:context] || {}).transform_values do |value|
          value.is_a?(String) ? Hstring.new(value).coerce_type : value
        end
      end

      def validate_options!
        validate_indices_option!
      end

      def repo_attributes(repo)
        return repo.lazy_document_attribute_names(true) if attributes.empty?

        repo.lazy_document_attribute_names(attributes)
      end
    end
  end
end
