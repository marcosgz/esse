# frozen_string_literal: true

module Esse
  # https://www.elastic.co/guide/en/elasticsearch/reference/1.7/indices.html
  class IndexSetting
    def initialize(body: {}, paths: [], globals: {})
      @globals = globals || {}
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
    alias_method :as_json, :to_h # backwards compatibility

    def body
      @globals.merge(to_h)
    end

    protected

    def from_template
      return if @paths.empty?

      loader = Esse::TemplateLoader.new(@paths)
      loader.read('{setting,settings}')
    end
  end
end
