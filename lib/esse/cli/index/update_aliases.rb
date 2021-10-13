# frozen_string_literal: true

require_relative 'base_operation'

module Esse
  module CLI
    class Index::UpdateAliases < Index::BaseOperation
      def run
        validate_options!
        indices.each do |index|
          index.elasticsearch.update_aliases!(**options)
        end
      end

      private

      def options
        @options.slice(*@options.keys - CLI_IGNORE_OPTS)
      end

      def validate_options!
        validate_indices_option!

        if @options[:suffix].nil?
          raise InvalidOption.new(<<~END)
            You must specify a suffix to update the aliases.
          END
        end
      end
    end
  end
end
