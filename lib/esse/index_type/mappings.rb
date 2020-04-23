# frozen_string_literal: true

module Esse
  # https://www.elastic.co/guide/en/elasticsearch/reference/7.6/removal-of-types.html
  # I think we should only keep the mapping in the index level. But it will lost the the `define_type` flexibility
  class IndexType
    # https://github.com/elastic/elasticsearch-ruby/blob/master/elasticsearch-api/lib/elasticsearch/api/actions/indices/put_mapping.rb
    module ClassMethods
      def mappings(hash = {}, &block)
        @mapping = Esse::Types::Mapping.new(self, hash)
        return unless block_given?

        @mapping.define_singleton_method(:as_json, &block)
      end

      private

      def mapping
        @mapping ||= Esse::Types::Mapping.new(self)
      end
    end

    extend ClassMethods
  end
end
