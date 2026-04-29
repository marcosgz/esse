# frozen_string_literal: true

module Esse
  # https://github.com/elastic/elasticsearch-ruby/blob/master/elasticsearch-api/lib/elasticsearch/api/actions/indices/put_settings.rb
  class Index
    module ClassMethods
      # Backwards-compatible alias. The canonical list now lives on
      # +Esse::IndexSetting::INDEX_SIMPLIFIED_SETTINGS+ so that the merge
      # logic and the simplified-key promotion stay in sync.
      INDEX_SIMPLIFIED_SETTINGS = Esse::IndexSetting::INDEX_SIMPLIFIED_SETTINGS

      def settings_hash(settings: nil)
        # Normalize each side (global vs local) separately before merging so
        # a flat global key (e.g. top-level :number_of_shards) cannot clobber
        # an explicit nested local value (e.g. :index => { :number_of_shards => 8 }).
        global = Esse::IndexSetting.normalize(setting.globals)
        local = Esse::IndexSetting.normalize(setting.to_h)
        values = HashUtils.deep_merge(global, local)

        if settings.is_a?(Hash)
          values = HashUtils.deep_merge(values, Esse::IndexSetting.normalize(settings))
        end

        if values[:index].is_a?(Hash)
          INDEX_SIMPLIFIED_SETTINGS.each { |key| values[:index].delete(key) if values[:index][key].nil? }
          values.delete(:index) if values[:index].empty?
        end

        { Esse::SETTING_ROOT_KEY => values }
      end

      # Define /_settings definition by each index.
      #
      # +hash+: The body of the request includes the updated settings.
      # +block+: Overwrite default :to_h from IndexSetting instance
      #
      # Example:
      #
      #   class UserIndex < Esse::Index
      #     settings {
      #       index: { number_of_replicas: 4 }
      #     }
      #   end
      #
      #   class UserIndex < Esse::Index
      #     settings do
      #       # do something to load settings..
      #     end
      #   end
      def settings(hash = {}, &block)
        @setting = Esse::IndexSetting.new(body: hash, paths: template_dirs, globals: -> { cluster.settings })
        return unless block

        @setting.define_singleton_method(:to_h, &block)
      end

      private

      def setting
        @setting ||= Esse::IndexSetting.new(paths: template_dirs, globals: -> { cluster.settings })
      end
    end

    extend ClassMethods
  end
end
