# frozen_string_literal: true

module Esse
  module Deprecations
    class IndexBackendDelegator
      extend Gem::Deprecate

      def initialize(index)
        @index = index
      end

      def aliases(**kwargs)
        @index.aliases(**kwargs)
      end
      deprecate :aliases, 'Esse::Index.aliases', 2023, 12

      def indices(**kwargs)
        @index.indices_pointing_to_alias(**kwargs)
      end
      deprecate :indices, 'Esse::Index.indices_pointing_to_alias', 2023, 12

      def update_aliases!(**kwargs)
        @index.update_aliases(**kwargs)
      end
      deprecate :update_aliases!, 'Esse::Index.update_aliases', 2023, 12

      def update_aliases(**kwargs)
        @index.update_aliases(**kwargs)
      rescue Esse::Transport::NotFoundError
        { 'errors' => true }
      end
      deprecate :update_aliases, 'Esse::Index.update_aliases', 2023, 12

      def create_index(**kwargs)
        @index.create_index(**kwargs)
      end
      deprecate :create_index, 'Esse::Index.create_index', 2023, 12

      def create_index!(**kwargs)
        @index.create_index(**kwargs)
      end
      deprecate :create_index!, 'Esse::Index.create_index', 2023, 12

      def close(**kwargs)
        @index.close(**kwargs)
      end
      deprecate :close, 'Esse::Index.close', 2023, 12

      def close!(**kwargs)
        @index.close(**kwargs)
      end
      deprecate :close!, 'Esse::Index.close', 2023, 12

      def open(**kwargs)
        @index.open(**kwargs)
      end
      deprecate :open, 'Esse::Index.open', 2023, 12

      def open!(**kwargs)
        @index.open(**kwargs)
      end
      deprecate :open!, 'Esse::Index.open', 2023, 12

      def refresh(**kwargs)
        @index.refresh(**kwargs)
      end
      deprecate :refresh, 'Esse::Index.refresh', 2023, 12

      def refresh!(**kwargs)
        @index.refresh(**kwargs)
      end
      deprecate :refresh!, 'Esse::Index.refresh', 2023, 12

      def delete_index(**kwargs)
        @index.delete_index(**kwargs)
      end
      deprecate :delete_index, 'Esse::Index.delete_index', 2023, 12

      def delete_index!(**kwargs)
        @index.delete_index(**kwargs)
      end
      deprecate :delete_index!, 'Esse::Index.delete_index', 2023, 12

      def index_exist?(**kwargs)
        @index.index_exist?(**kwargs)
      end
      deprecate :index_exist?, 'Esse::Index.index_exist?', 2023, 12

      def update_mapping!(**kwargs)
        @index.update_mapping(**kwargs)
      end
      deprecate :update_mapping!, 'Esse::Index.update_mapping', 2023, 12

      def update_mapping(**kwargs)
        @index.update_mapping(**kwargs)
      end
      deprecate :update_mapping, 'Esse::Index.update_mapping', 2023, 12

      def update_settings!(**kwargs)
        @index.update_settings(**kwargs)
      end
      deprecate :update_settings!, 'Esse::Index.update_settings', 2023, 12

      def update_settings(**kwargs)
        @index.update_settings(**kwargs)
      end
      deprecate :update_settings, 'Esse::Index.update_settings', 2023, 12

      def reset_index!(**kwargs)
        @index.reset_index(**kwargs)
      end
      deprecate :reset_index!, 'Esse::Index.reset_index', 2023, 12

      def import(**kwargs)
        @index.import(**kwargs)
      end
      deprecate :import, 'Esse::Index.import', 2023, 12

      def import!(**kwargs)
        @index.import(**kwargs)
      end
      deprecate :import!, 'Esse::Index.import', 2023, 12

      def bulk!(**kwargs)
        @index.bulk(**kwargs)
      end
      deprecate :bulk!, 'Esse::Index.bulk', 2023, 12

      def bulk(**kwargs)
        @index.bulk(**kwargs)
      end
      deprecate :bulk, 'Esse::Index.bulk', 2023, 12

      def index!(**kwargs)
        @index.index(**kwargs)
      end
      deprecate :index!, 'Esse::Index.index', 2023, 12

      def index(**kwargs)
        @index.index(**kwargs)
      end
      deprecate :index, 'Esse::Index.index', 2023, 12

      def update!(**kwargs)
        @index.update(**kwargs)
      end
      deprecate :update!, 'Esse::Index.update', 2023, 12

      def update(**kwargs)
        @index.update(**kwargs)
      end
      deprecate :update, 'Esse::Index.update', 2023, 12

      def delete!(**kwargs)
        @index.delete(**kwargs)
      end
      deprecate :delete!, 'Esse::Index.delete', 2023, 12

      def delete(**kwargs)
        @index.delete(**kwargs)
      end
      deprecate :delete, 'Esse::Index.delete', 2023, 12

      def count(**kwargs)
        @index.count(**kwargs)
      end
      deprecate :count, 'Esse::Index.count', 2023, 12

      def exist?(**kwargs)
        @index.exist?(**kwargs)
      end
      deprecate :exist?, 'Esse::Index.exist?', 2023, 12

      def find!(**kwargs)
        @index.get(**kwargs)
      end
      deprecate :find!, 'Esse::Index.find', 2023, 12

      def find(**kwargs)
        @index.get(**kwargs)
      end
      deprecate :find, 'Esse::Index.find', 2023, 12
    end
  end
end
