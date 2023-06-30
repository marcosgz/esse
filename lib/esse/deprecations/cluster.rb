# frozen_string_literal: true

module Esse
  class Cluster
    extend Gem::Deprecate

    def index_settings
      settings
    end
    deprecate :index_settings, :settings, 2023, 12

    def index_settings=(value)
      self.settings = value
    end
    deprecate :index_settings=, :settings=, 2023, 12

    def index_mappings
      mappings
    end
    deprecate :index_mappings, :mappings, 2023, 12

    def index_mappings=(value)
      self.mappings = value
    end
    deprecate :index_mappings=, :mappings=, 2023, 12
  end
end
