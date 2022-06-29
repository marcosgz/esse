# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require 'esse'
require 'support/class_helpers'
require 'support/config_helpers'
require 'support/fixtures'
require 'support/elasticsearch_helpers'
require 'support/webmock'
require 'support/hooks/service_type'
require 'support/hooks/service_version'
require 'support/hooks/pub_sub'
require 'pry'

Hooks::ServiceVersion.banner!

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.include ClassHelpers
  config.include ConfigHelpers
  config.include Fixtures
  config.include ElasticsearchHelpers
  config.include Hooks::ServiceType
  config.include Hooks::ServiceVersion
  config.include Hooks::PubSub
end

def stack_describe(version, desc, *args, **kwargs, &block)
  RSpec.describe ["[ES #{version}]", desc].join(' '), *args, **kwargs, es_version: version, &block
end
