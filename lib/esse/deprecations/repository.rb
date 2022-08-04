# frozen_string_literal: true

module Esse
  class Repository
    class << self
      extend Gem::Deprecate

      def type_name
        document_type
      end
      deprecate :type_name, :document_type, 2022, 10
    end
  end
end
