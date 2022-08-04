# frozen_string_literal: true

module Esse
  class Cluster
    extend Gem::Deprecate

    def index_settings
      settings
    end
    deprecate :index_settings, :settings, 2022, 10

    def index_settings=(value)
      self.settings = value
    end
    deprecate :index_settings=, :settings=, 2022, 10
  end
end
