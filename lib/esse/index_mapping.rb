# frozen_string_literal: true

module Esse
  class IndexMapping
    FILENAMES = %w[mapping mappings].freeze

    def initialize(body: {}, paths: [], filenames: FILENAMES, globals: nil)
      @paths = Array(paths)
      @filenames = Array(filenames)
      @mappings = body
      @globals = globals || -> { {} }
    end

    # This method will be overwrited when passing a block during the
    # mapping defination
    def to_h
      return @mappings unless @mappings.empty?

      from_template || @mappings
    end

    def body
      global = HashUtils.deep_transform_keys(@globals.call, &:to_sym)
      local = HashUtils.deep_transform_keys(to_h.dup, &:to_sym)
      dynamic_template = DynamicTemplate.new(global[:dynamic_templates])
      dynamic_template.merge!(local.delete(:dynamic_templates))
      if dynamic_template.any?
        global[:dynamic_templates] = dynamic_template.to_a
      end
      HashUtils.deep_merge(global, local)
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
