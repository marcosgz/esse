# frozen_string_literal: true

module Esse
  class NullDocument < Esse::Document
    def initialize
      @object = nil
      @options = {}
    end

    # @return [NilClass] the document ID
    def id
      nil
    end

    # @return [NilClass] the document type
    def type
      nil
    end

    # @return [NilClass] the document routing
    def routing
      nil
    end

    # @return [NilClass] the document meta
    def meta
      {}
    end

    # @return [NilClass] the document source
    def source
      nil
    end
  end
end
