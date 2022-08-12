# frozen_string_literal: true

require 'multi_json'
require 'forwardable'

begin
  require 'elasticsearch'
rescue LoadError
end

begin
  require 'opensearch'
rescue LoadError
end

module Esse
  SETTING_ROOT_KEY = :settings
  MAPPING_ROOT_KEY = :mappings
  DEFAULT_REPO_NAME = 'default'
  CLI_IGNORE_OPTS = %i[
    require
    silent
  ].freeze
  CLI_CONFIG_PATHS = %w[
    Essefile
    config/esse.rb
    config/initializers/esse.rb
  ].freeze
end

require_relative 'esse/plugins'
require_relative 'esse/core'
require_relative 'esse/errors'
require_relative 'esse/index'
