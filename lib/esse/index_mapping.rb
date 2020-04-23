# frozen_string_literal: true

module Esse
  class IndexMapping
    FILENAMES = %w[mapping mappings].freeze

    def initialize(body: {}, paths: [], filenames: FILENAMES)
      @paths = Array(paths)
      @filenames = Array(filenames)
      @mappings = body
    end

    # This method will be overwrited when passing a block during the
    # mapping defination
    def as_json
      return @mappings unless @mappings.empty?

      from_template || @mappings
    end

    def body
      as_json
    end

    def empty?
      body.empty?
    end

    protected

    def from_template
      return if @paths.empty?

      loader = Esse::TemplateLoader.new(@paths)
      loader.read(*@filenames)
    end
  end
end
