# frozen_string_literal: true

module Esse
  # https://github.com/elastic/elasticsearch-ruby/blob/master/elasticsearch-api/lib/elasticsearch/api/actions/indices/put_settings.rb
  class Index
    module ClassMethods
      # Elasticsearch supports passing index.* related settings directly in the body of the request.
      # We are moving it to the index key to make it more explicit and to be the source-of-truth when merging settings.
      # So the settings `{ number_of_shards: 1 }` will be transformed to `{ index: { number_of_shards: 1 } }`
      INDEX_SIMPLIFIED_SETTINGS = %i[
        number_of_shards
        number_of_replicas
        refresh_interval
      ].freeze

      def settings_hash(settings: nil)
        hash = setting.body
        values = (hash.key?(Esse::SETTING_ROOT_KEY) ? hash[Esse::SETTING_ROOT_KEY] : hash)
        values = HashUtils.explode_keys(values)
        if settings.is_a?(Hash)
          values = HashUtils.deep_merge(values, HashUtils.explode_keys(settings))
        end
        INDEX_SIMPLIFIED_SETTINGS.each do |key|
          next unless values.key?(key)

          (values[:index] ||= {}).merge!(key => values.delete(key))
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
