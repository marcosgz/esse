# frozen_string_literal: true

module Esse
  module Backend
    class Index
      extend Gem::Deprecate

      def aliases(**kwargs)
        @index.aliases(**kwargs)
      end
      deprecate :aliases, "Esse::Index.aliases", 2022, 11

      def indices(**kwargs)
        @index.indices_pointing_to_alias(**kwargs)
      end
      deprecate :indices, "Esse::Index.indices_pointing_to_alias", 2022, 11

      def update_aliases!(**kwargs)
        @index.update_aliases(**kwargs)
      end
      deprecate :update_aliases!, "Esse::Index.update_aliases", 2022, 11

      def update_aliases(**kwargs)
        @index.update_aliases(**kwargs)
      rescue Esse::Transport::NotFoundError
        { 'errors' => true }
      end
      deprecate :update_aliases, "Esse::Index.update_aliases", 2022, 11

      def create_index(**kwargs)
        @index.create_index(**kwargs)
      end
      deprecate :create_index, "Esse::Index.create_index", 2022, 11

      def create_index!(**kwargs)
        @index.create_index(**kwargs)
      end
      deprecate :create_index!, "Esse::Index.create_index", 2022, 11

      def close(**kwargs)
        @index.close(**kwargs)
      end
      deprecate :close, "Esse::Index.close", 2022, 11

      def close!(**kwargs)
        @index.close(**kwargs)
      end
      deprecate :close!, "Esse::Index.close", 2022, 11

      def open(**kwargs)
        @index.open(**kwargs)
      end
      deprecate :open, "Esse::Index.open", 2022, 11

      def open!(**kwargs)
        @index.open(**kwargs)
      end
      deprecate :open!, "Esse::Index.open", 2022, 11

      def refresh(**kwargs)
        @index.refresh(**kwargs)
      end
      deprecate :refresh, "Esse::Index.refresh", 2022, 11

      def refresh!(**kwargs)
        @index.refresh(**kwargs)
      end
      deprecate :refresh!, "Esse::Index.refresh", 2022, 11

      def delete_index(**kwargs)
        @index.delete_index(**kwargs)
      end
      deprecate :delete_index, "Esse::Index.delete_index", 2022, 11

      def delete_index!(**kwargs)
        @index.delete_index(**kwargs)
      end
      deprecate :delete_index!, "Esse::Index.delete_index", 2022, 11

      def index_exist?(**kwargs)
        @index.index_exist?(**kwargs)
      end
      deprecate :index_exist?, "Esse::Index.index_exist?", 2022, 11
    end
  end
end
