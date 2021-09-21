# frozen_string_literal: true

require_relative 'base_operation'

module Esse
  module CLI
    class Index::Open < Index::BaseOperation
      def run
        validate_options!
        indices.each do |index|
          index.elasticsearch.open!(**options)
          print_success 'Index %<name>s successfuly opened',
            name: index.elasticsearch.send(:index_name, suffix: options[:suffix]) # @todo use pub/sub api to get real index name
        end
      end

      private

      def options
        @options.slice(*@options.keys - %i[require])
      end

      def validate_options!
        validate_indices_option!
      end
    end
  end
end
