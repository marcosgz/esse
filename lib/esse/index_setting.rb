# frozen_string_literal: true

module Esse
  # https://www.elastic.co/guide/en/elasticsearch/reference/1.7/indices.html
  class IndexSetting
    # Top-level keys that Elasticsearch/OpenSearch accept either flat or nested
    # under `index:`. We always promote them to the nested form so that values
    # from different sources (cluster globals vs per-index template) merge
    # predictably regardless of which form each side was authored in.
    INDEX_SIMPLIFIED_SETTINGS = %i[
      number_of_shards
      number_of_replicas
      refresh_interval
      mapping
    ].freeze

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
      global = HashUtils.deep_transform_keys(@globals.call, &:to_sym)
      local = HashUtils.deep_transform_keys(to_h, &:to_sym)
      HashUtils.deep_merge(global, local)
    end

    # Returns the raw (unsymbolized) global settings as supplied by the
    # +globals+ proc. Public so that callers like
    # +Esse::Index.settings_hash+ can normalize it independently before
    # merging it with the local template — preventing a flat global value
    # from clobbering a nested local value once both are merged.
    def globals
      @globals.call || {}
    end

    # Normalize a settings hash by:
    #   * symbolizing keys
    #   * stripping the `:settings` root if present
    #   * exploding dotted keys ('index.number_of_replicas' -> { index: { number_of_replicas: ... } })
    #   * promoting simplified flat keys (number_of_shards, etc.) into the
    #     nested `:index` form, preserving any value already present under
    #     `:index` (we never overwrite an explicit nested setting with a
    #     flat value from the same source).
    def self.normalize(hash)
      values = HashUtils.deep_transform_keys(hash || {}, &:to_sym)
      values = values[Esse::SETTING_ROOT_KEY] if values.key?(Esse::SETTING_ROOT_KEY)
      values = HashUtils.explode_keys(values)
      INDEX_SIMPLIFIED_SETTINGS.each do |key|
        next unless values.key?(key)
        value = values.delete(key)
        next if value.nil?

        values[:index] ||= {}
        values[:index][key] = value unless values[:index].key?(key)
      end
      values
    end

    protected

    def from_template
      return if @paths.empty?

      loader = Esse::TemplateLoader.new(@paths)
      loader.read('{setting,settings}')
    end
  end
end
