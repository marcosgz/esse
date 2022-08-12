# frozen_string_literal: true

module Esse
  class Index
    module ObjectDocumentMapper
      # Convert ruby object to json. Arguments will be same of passed through the
      # collection. It's allowed a block or a class with the `to_h` instance method.
      # Example with block
      #   serializer :user do |model, **context|
      #     {
      #       id: model.id,
      #       admin: context[:is_admin],
      #     }
      #   end
      # Example with serializer class
      #   serializer UserSerializer
      def serializer(*args, &block)
        repo_name, klass = args
        # >> Backward compatibility for the old collection syntax without explicit repo_name
        if repo_name && klass.nil? && !repo_name.is_a?(String) && !repo_name.is_a?(Symbol)
          klass = repo_name
          repo_name = DEFAULT_REPO_NAME
        end
        repo_name = repo_name&.to_s || DEFAULT_REPO_NAME
        # <<
        find_or_define_repo(repo_name).serializer(klass, &block)
      end

      # Used to define the source of data. A block is required. And its
      # content should yield an array of each object that should be serialized.
      # The list of arguments will be passed throught the serializer method.
      #
      # Example:
      #   collection :admin, AdminStore
      #   collection :user do |**conditions, &block|
      #     User.where(conditions).find_in_batches(batch_size: 5000) do |batch|
      #       block.call(batch, conditions)
      #     end
      #   end
      #
      # @param [String] name The identification of the collection.
      # @param [Class] klass The class of the collection. (Optional when block is passed)
      # @param [Proc] block The block that will be used to iterate over the collection. (Optional when using a class)
      # @return [void]
      def collection(*args, **kwargs, &block)
        repo_name, collection_klass = args
        # >> Backward compatibility for the old collection syntax without explicit repo_name
        if repo_name && !repo_name.is_a?(Symbol) && !repo_name.is_a?(String) && collection_klass.nil?
          collection_klass = repo_name
          repo_name = DEFAULT_REPO_NAME
        end
        repo_name = repo_name&.to_s || DEFAULT_REPO_NAME
        # <<
        find_or_define_repo(repo_name).collection(collection_klass, **kwargs, &block)
      end

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
          each_serialized_batch(repo_name, **kwargs) do |documents, **_collection_kargs|
            documents.each { |document| yielder.yield(document) }
          end
        end
      end

      private

      def find_or_define_repo(repo_name)
        return repo_hash[repo_name] if repo_hash.key?(repo_name)

        repository(repo_name) {}
      end
    end

    extend ObjectDocumentMapper
  end
end
