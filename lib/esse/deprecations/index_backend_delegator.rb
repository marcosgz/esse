# frozen_string_literal: true

module Esse
  module Deprecations
    class IndexBackendDelegator
      extend Esse::Deprecations::Deprecate

      def initialize(namespace, index)
        @namespace = namespace
        @index = index
      end

      def aliases(**kwargs)
        warning("#{@index}.#{@namespace}.aliases", "#{@index}.aliases", 2023, 12)
        @index.aliases(**kwargs)
      end

      def indices(**kwargs)
        warning("#{@index}.#{@namespace}.indices", "#{@index}.indices_pointing_to_alias", 2023, 12)
        @index.indices_pointing_to_alias(**kwargs)
      end

      def update_aliases!(**kwargs)
        warning("#{@index}.#{@namespace}.update_aliases!", "#{@index}.update_aliases", 2023, 12)
        @index.update_aliases(**kwargs)
      end

      def update_aliases(**kwargs)
        warning("#{@index}.#{@namespace}.update_aliases", "#{@index}.update_aliases", 2023, 12)

        @index.update_aliases(**kwargs)
      rescue Esse::Transport::NotFoundError
        { 'errors' => true }
      end

      def create_index(**kwargs)
        warning("#{@index}.#{@namespace}.create_index", "#{@index}.create_index", 2023, 12)

        @index.create_index(**kwargs)
      end

      def create_index!(**kwargs)
        warning("#{@index}.#{@namespace}.create_index!", "#{@index}.create_index", 2023, 12)

        @index.create_index(**kwargs)
      end

      def close(**kwargs)
        warning("#{@index}.#{@namespace}.close", "#{@index}.close", 2023, 12)

        @index.close(**kwargs)
      end

      def close!(**kwargs)
        warning("#{@index}.#{@namespace}.close!", "#{@index}.close", 2023, 12)

        @index.close(**kwargs)
      end

      def open(**kwargs)
        warning("#{@index}.#{@namespace}.open", "#{@index}.open", 2023, 12)

        @index.open(**kwargs)
      end

      def open!(**kwargs)
        warning("#{@index}.#{@namespace}.open!", "#{@index}.open", 2023, 12)

        @index.open(**kwargs)
      end

      def refresh(**kwargs)
        warning("#{@index}.#{@namespace}.refresh", "#{@index}.refresh", 2023, 12)

        @index.refresh(**kwargs)
      end

      def refresh!(**kwargs)
        warning("#{@index}.#{@namespace}.refresh!", "#{@index}.refresh", 2023, 12)

        @index.refresh(**kwargs)
      end

      def delete_index(**kwargs)
        warning("#{@index}.#{@namespace}.delete_index", "#{@index}.delete_index", 2023, 12)

        @index.delete_index(**kwargs)
      end

      def delete_index!(**kwargs)
        warning("#{@index}.#{@namespace}.delete_index!", "#{@index}.delete_index", 2023, 12)

        @index.delete_index(**kwargs)
      end

      def index_exist?(**kwargs)
        warning("#{@index}.#{@namespace}.index_exist?", "#{@index}.index_exist?", 2023, 12)

        @index.index_exist?(**kwargs)
      end

      def update_mapping!(**kwargs)
        warning("#{@index}.#{@namespace}.update_mapping!", "#{@index}.update_mapping", 2023, 12)

        @index.update_mapping(**kwargs)
      end

      def update_mapping(**kwargs)
        warning("#{@index}.#{@namespace}.update_mapping", "#{@index}.update_mapping", 2023, 12)

        @index.update_mapping(**kwargs)
      end

      def update_settings!(**kwargs)
        warning("#{@index}.#{@namespace}.update_settings!", "#{@index}.update_settings", 2023, 12)

        @index.update_settings(**kwargs)
      end

      def update_settings(**kwargs)
        warning("#{@index}.#{@namespace}.update_settings", "#{@index}.update_settings", 2023, 12)

        @index.update_settings(**kwargs)
      end

      def reset_index!(**kwargs)
        warning("#{@index}.#{@namespace}.reset_index!", "#{@index}.reset_index", 2023, 12)

        @index.reset_index(**kwargs)
      end

      def import(**kwargs)
        warning("#{@index}.#{@namespace}.import", "#{@index}.import", 2023, 12)

        @index.import(**kwargs)
      end

      def import!(**kwargs)
        warning("#{@index}.#{@namespace}.import!", "#{@index}.import", 2023, 12)

        @index.import(**kwargs)
      end

      def bulk!(**kwargs)
        warning("#{@index}.#{@namespace}.bulk!", "#{@index}.bulk", 2023, 12)

        @index.bulk(**kwargs)
      end

      def bulk(**kwargs)
        warning("#{@index}.#{@namespace}.bulk", "#{@index}.bulk", 2023, 12)

        @index.bulk(**kwargs)
      end

      def index!(**kwargs)
        warning("#{@index}.#{@namespace}.index!", "#{@index}.index", 2023, 12)

        @index.index(**kwargs)
      end

      def index(**kwargs)
        warning("#{@index}.#{@namespace}.index", "#{@index}.index", 2023, 12)

        @index.index(**kwargs)
      end

      def update!(**kwargs)
        warning("#{@index}.#{@namespace}.update!", "#{@index}.update", 2023, 12)

        @index.update(**kwargs)
      end

      def update(**kwargs)
        warning("#{@index}.#{@namespace}.update", "#{@index}.update", 2023, 12)

        @index.update(**kwargs)
      end

      def delete!(**kwargs)
        warning("#{@index}.#{@namespace}.delete!", "#{@index}.delete", 2023, 12)

        @index.delete(**kwargs)
      end

      def delete(**kwargs)
        warning("#{@index}.#{@namespace}.delete", "#{@index}.delete", 2023, 12)

        @index.delete(**kwargs)
      end

      def count(**kwargs)
        warning("#{@index}.#{@namespace}.count", "#{@index}.count", 2023, 12)

        @index.count(**kwargs)
      end

      def exist?(**kwargs)
        warning("#{@index}.#{@namespace}.exist?", "#{@index}.exist?", 2023, 12)

        @index.exist?(**kwargs)
      end

      def find!(**kwargs)
        warning("#{@index}.#{@namespace}.find!", "#{@index}.get", 2023, 12)

        @index.get(**kwargs)
      end

      def find(**kwargs)
        warning("#{@index}.#{@namespace}.find", "#{@index}.get", 2023, 12)

        @index.get(**kwargs)
      end
    end
  end
end
