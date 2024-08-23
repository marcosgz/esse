# frozen_string_literal: true

module Esse
  class Index
    module ObjectDocumentMapper
      # Wrap collection data into serialized batches
      #
      # @param [String, NilClass] repo_name The repository identifier
      # @param [Hash] kwargs The context
      # @return [Enumerator] The enumerator
      # @yield [Array, **context] serialized collection and the optional context from the collection
      def each_serialized_batch(repo_name = nil, **kwargs, &block)
        (repo_name ? [repo(repo_name)] : repo_hash.values).each do |repo|
          repo.each_serialized_batch(**kwargs, &block)
        end
      end

      # Wrap collection data into serialized documents
      #
      # Example:
      #    GeosIndex.documents(id: 1).first
      #
      # @param [String, NilClass] repo_name The repository identifier
      # @return [Enumerator] All serialized entries
      def documents(repo_name = nil, **kwargs)
        Enumerator.new do |yielder|
          each_serialized_batch(repo_name, **kwargs) do |documents|
            documents.each { |document| yielder.yield(document) }
          end
        end
      end
    end

    extend ObjectDocumentMapper
  end
end
