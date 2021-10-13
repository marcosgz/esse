# frozen_string_literal: true

module Esse
  # https://www.elastic.co/guide/en/elasticsearch/reference/1.7/indices.html
  class IndexSetting
    # @param [Hash] options
    # @option options [Proc] :globals  A proc that will be called to load global settings
    # @option options [Array] :paths   A list of paths to load settings from
    # @option options [Hash]  :body    A hash of settings to override
    def initialize(body: {}, paths: [], globals: nil)
      @globals = globals || -> { {} }
      @paths = Array(paths)
      @settings = body
    end

    # This method will be overwrited when passing a block during the settings
    # defination on index class.
    #
    # Example:
    #   class UserIndex < Esse::Index
    #     settings do
    #       # do something to load settings..
    #     end
    #   end
    #
    def to_h
      return @settings unless @settings.empty?

      from_template || @settings
    end

    def body
      HashUtils.deep_merge(@globals.call, to_h)
    end

    protected

    def from_template
      return if @paths.empty?

      loader = Esse::TemplateLoader.new(@paths)
      loader.read('{setting,settings}')
    end
  end
end
