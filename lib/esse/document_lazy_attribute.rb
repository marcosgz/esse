# frozen_string_literal: true

module Esse
  class DocumentLazyAttribute
    # Returns an Hash with the document ID as key and attribute data as value.
    def call(document_ids)
      raise NotImplementedError, 'Override this method to return the document attribute data'
    end
  end
end
