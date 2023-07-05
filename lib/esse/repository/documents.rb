# frozen_string_literal: true

module Esse
  class Repository
    module ClassMethods
      def import(**kwargs)
        index.import(repo_name, **kwargs)
      end
    end

    extend ClassMethods
  end
end
