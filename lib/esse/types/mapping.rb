# frozen_string_literal: true

module Esse
  module Types
    class Mapping
      def initialize(index_type, hash = {})
        @parent = index_type
        @mappings = hash
      end

      # This method will be overwrited when passing a block during the
      # mapping defination
      def as_json
        return @mappings unless @mappings.empty?

        from_template || @mappings
      end

      def body
        as_json
      end

      protected

      def from_template
        loader = Esse::TemplateLoader.new(paths)
        loader.read("#{@type_name}_{mapping,mappings}", '{mapping,mappings}')
      end

      def paths
        return [] unless @parent
        return [] unless @parent < Esse::IndexType

        base_dir = Hstring.new(@parent.index.name).underscore.presence.value
        return [] unless base_dir

        @type_name = @parent.type_name

        [
          Esse.config.indices_directory.join(base_dir, @type_name),
          Esse.config.indices_directory.join(base_dir, 'templates'),
          Esse.config.indices_directory.join(base_dir)
        ]
      end
    end
  end
end
