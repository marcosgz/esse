# frozen_string_literal: true

module Esse
  class Collection
    include Enumerable
    attr_reader :options

    def initialize(**options)
      @options = options
    end

    # @yield [<Array, Hash>] A batch of documents to be serialized and indexed.
    # @abstract Override this method to yield each chunk of documents with optional metadata
    def each
      raise NotImplementedError, 'Override this method to iterate over the collection'
    end
  end
end
