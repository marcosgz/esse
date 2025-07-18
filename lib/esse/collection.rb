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

    # @yield [<Array>] A batch of document IDs to be processed.
    # @abstract Override this method to yield each chunk of document IDs
    def each_batch_ids
      raise NotImplementedError, 'Override this method to iterate over the collection in batches of IDs'
    end
  end
end
