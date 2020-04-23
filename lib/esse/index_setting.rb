# frozen_string_literal: true

module Esse
  # https://www.elastic.co/guide/en/elasticsearch/reference/1.7/indices.html
  class IndexSetting
    def initialize(index, settings = {})
      @parent = index
      @settings = settings
    end

    # This method will be overwrited when passing a block during the settings
    # defination on index class.
    #
    # Example:
    #   class UserIndex < Esse::Index
    #     settings do
    #       JSON.parse('my/path/to/json')
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
      loader = Esse::TemplateLoader.new(paths)
      loader.read('{setting,settings}')
    end

    def paths
      return [] unless @parent
      return [] unless @parent < Esse::Index

      dir = Hstring.new(@parent.name).underscore.presence.value
      return [] unless dir

      [
        Esse.config.indices_directory.join(dir, 'templates'),
        Esse.config.indices_directory.join(dir)
      ]
    end
  end
end
