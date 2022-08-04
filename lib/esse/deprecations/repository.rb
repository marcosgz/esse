# frozen_string_literal: true

module Esse
  class Repository
    class << self
      extend Gem::Deprecate

      def type_name
        document_type
      end
      deprecate :type_name, :document_type, 2022, 10

      def mappings(*args, &block)
        index.mappings(*args, &block)
      end
      deprecate :mappings, "Esse::Index.mappings", 2022, 10
    end
  end
end
