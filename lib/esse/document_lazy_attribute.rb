# frozen_string_literal: true

module Esse
  class DocumentLazyAttribute
    attr_reader :options

    def initialize(**kwargs)
      @options = kwargs
    end

    # Returns an Hash with the document ID as key and attribute data as value.
    # @param doc_headers [Array<Esse::LazyDocumentHeader>] the document headers
    # @return [Hash] An Hash with the instance of document header as key and the attribute data as value.
    def call(doc_headers)
      raise NotImplementedError, 'Override this method to return the document attribute data'
    end
  end
end
