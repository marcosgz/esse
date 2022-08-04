# frozen_string_literal: true

module Esse
  # https://github.com/elastic/elasticsearch-ruby/blob/master/elasticsearch-api/lib/elasticsearch/api/actions/indices/put_settings.rb
  class Index
    module ClassMethods
      def settings_hash
        hash = setting.body
        { Esse::SETTING_ROOT_KEY => (hash.key?(Esse::SETTING_ROOT_KEY) ? hash[Esse::SETTING_ROOT_KEY] : hash) }
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
      #       number_of_replicas: 4,
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
