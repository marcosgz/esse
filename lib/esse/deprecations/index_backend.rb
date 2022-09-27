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
    end
  end
end
