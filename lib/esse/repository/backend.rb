# frozen_string_literal: true

module Esse
  class Repository
    module ClassMethods
      def elasticsearch
        Esse::Backend::RepositoryBackend.new(self)
      end
      alias_method :backend, :elasticsearch
    end

    extend ClassMethods
  end
end
