# frozen_string_literal: true

module Esse
  class Repository
    class << self
      extend Esse::Deprecations::Deprecate

      def type_name
        document_type
      end
      deprecate :type_name, :document_type, 2023, 12

      def mappings(*args, &block)
        index.mappings(*args, &block)
      end
      deprecate :mappings, 'Esse::Index.mappings', 2023, 12
    end
  end
end
