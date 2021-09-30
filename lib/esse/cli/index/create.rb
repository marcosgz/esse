# frozen_string_literal: true

require_relative 'base_operation'

module Esse
  module CLI
    class Index::Create < Index::BaseOperation
      def run
        validate_options!
        indices.each do |index|
          index.elasticsearch.create_index!(**options)
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
