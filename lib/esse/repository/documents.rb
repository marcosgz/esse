# frozen_string_literal: true

module Esse
  class Repository
    module ClassMethods
      def import(**kwargs)
        index.import(repo_name, **kwargs)
      end

      def update_documents_attribute(name, *ids_or_doc_headers, **kwargs)
        batch = documents_for_lazy_attribute(name, *ids_or_doc_headers)
        return if batch.empty?

        index.bulk(**kwargs, update: batch)
      end

      def documents_for_lazy_attribute(name, *ids_or_doc_headers)
        unless lazy_document_attribute?(name)
          raise ArgumentError, <<~MSG
            The attribute `#{name}` is not defined as a lazy document attribute.

            Define the attribute as a lazy document attribute using the `lazy_document_attribute` method.
          MSG
        end

        docs = LazyDocumentHeader.coerce_each(ids_or_doc_headers)
        return [] if docs.empty?

        arr = []
        result = fetch_lazy_document_attribute(name).call(docs)
        return [] unless result.is_a?(Hash)

        result.each do |key, datum|
          doc = docs.find { |d| d == key || d.id == key }
          next unless doc

          arr << doc.to_doc(name => datum)
        end
        arr
      end
    end

    extend ClassMethods
  end
end
