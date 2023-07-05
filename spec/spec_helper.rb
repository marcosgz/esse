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
require 'securerandom'

Hooks::ServiceVersion.banner!

Dir[File.expand_path('support/shared_contexts/**/*.rb', __dir__)].sort.each { |f| require f }

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.order = :random
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end
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

def stack_describe(distribution, version, desc, *args, **kwargs, &block)
  RSpec.describe ["[#{distribution} #{version}]", desc].join(' '), *args, **kwargs, es_version: version, &block
end
