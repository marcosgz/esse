# frozen_string_literal: true

module Esse
  class DocumentForPartialUpdate < Esse::Document
    extend Forwardable

    def_delegators :object, :id, :type, :routing, :options

    attr_reader :source

    def initialize(lazy_header, source:)
      @source = source
      super(lazy_header)
    end
  end
end
