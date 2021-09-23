# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require 'esse'
require 'support/class_helpers'
require 'support/config_helpers'
require 'support/elasticsearch_helpers'
require 'support/webmock'
require 'support/hooks/es_version'
require 'support/hooks/pub_sub'
require 'pry'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.include ClassHelpers
  config.include ConfigHelpers
  config.include ElasticsearchHelpers
  config.include Hooks::EsVersion
  config.include Hooks::PubSub
end
