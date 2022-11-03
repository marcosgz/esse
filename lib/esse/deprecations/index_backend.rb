# frozen_string_literal: true

module Esse
  module Backend
    class Index
      extend Gem::Deprecate

      def aliases(**kwargs)
        @index.aliases(**kwargs)
      end
      deprecate :aliases, 'Esse::Index.aliases', 2023, 1

      def indices(**kwargs)
        @index.indices_pointing_to_alias(**kwargs)
      end
      deprecate :indices, 'Esse::Index.indices_pointing_to_alias', 2023, 1

      def update_aliases!(**kwargs)
        @index.update_aliases(**kwargs)
      end
      deprecate :update_aliases!, 'Esse::Index.update_aliases', 2023, 1

      def update_aliases(**kwargs)
        @index.update_aliases(**kwargs)
      rescue Esse::Transport::NotFoundError
        { 'errors' => true }
      end
      deprecate :update_aliases, 'Esse::Index.update_aliases', 2023, 1

      def create_index(**kwargs)
        @index.create_index(**kwargs)
      end
      deprecate :create_index, 'Esse::Index.create_index', 2023, 1

      def create_index!(**kwargs)
        @index.create_index(**kwargs)
      end
      deprecate :create_index!, 'Esse::Index.create_index', 2023, 1

      def close(**kwargs)
        @index.close(**kwargs)
      end
      deprecate :close, 'Esse::Index.close', 2023, 1

      def close!(**kwargs)
        @index.close(**kwargs)
      end
      deprecate :close!, 'Esse::Index.close', 2023, 1

      def open(**kwargs)
        @index.open(**kwargs)
      end
      deprecate :open, 'Esse::Index.open', 2023, 1

      def open!(**kwargs)
        @index.open(**kwargs)
      end
      deprecate :open!, 'Esse::Index.open', 2023, 1

      def refresh(**kwargs)
        @index.refresh(**kwargs)
      end
      deprecate :refresh, 'Esse::Index.refresh', 2023, 1

      def refresh!(**kwargs)
        @index.refresh(**kwargs)
      end
      deprecate :refresh!, 'Esse::Index.refresh', 2023, 1

      def delete_index(**kwargs)
        @index.delete_index(**kwargs)
      end
      deprecate :delete_index, 'Esse::Index.delete_index', 2023, 1

      def delete_index!(**kwargs)
        @index.delete_index(**kwargs)
      end
      deprecate :delete_index!, 'Esse::Index.delete_index', 2023, 1

      def index_exist?(**kwargs)
        @index.index_exist?(**kwargs)
      end
      deprecate :index_exist?, 'Esse::Index.index_exist?', 2023, 1

      def update_mapping!(**kwargs)
        @index.update_mapping(**kwargs)
      end
      deprecate :update_mapping!, 'Esse::Index.update_mapping', 2023, 1

      def update_mapping(**kwargs)
        @index.update_mapping(**kwargs)
      end
      deprecate :update_mapping, 'Esse::Index.update_mapping', 2023, 1

      def update_settings!(**kwargs)
        @index.update_settings(**kwargs)
      end
      deprecate :update_settings!, 'Esse::Index.update_settings', 2023, 1

      def update_settings(**kwargs)
        @index.update_settings(**kwargs)
      end
      deprecate :update_settings, 'Esse::Index.update_settings', 2023, 1

      def reset_index!(**kwargs)
        @index.reset_index(**kwargs)
      end
      deprecate :reset_index!, 'Esse::Index.reset_index', 2023, 1
    end
  end
end
