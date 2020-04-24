# frozen_string_literal: true

module Esse
  # https://www.elastic.co/guide/en/elasticsearch/reference/1.7/indices.html
  class IndexSetting
    def initialize(body: {}, paths: [])
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
    def as_json
      return @settings unless @settings.empty?

      from_template || @settings
    end

    def body
      global_settings.merge(as_json)
    end

    protected

    def global_settings
      Esse.config.index_settings
    end

    def from_template
      return if @paths.empty?

      loader = Esse::TemplateLoader.new(@paths)
      loader.read('{setting,settings}')
    end
  end
end
