# frozen_string_literal: true

module EsseConfig
  DEFAULTS = {
    index_prefix: 'test',
    indices_directory: 'tmp/indices',
    index_settings: {}
  }.freeze

  def reset_esse_config
    Esse.instance_variable_set(:@config, nil)
  end

  def with_config(opts = {})
    settings = DEFAULTS.dup.merge(opts)
    Esse.config.setup(settings)

    yield Esse.config

    reset_esse_config
  end
end

RSpec.configure do |config|
  config.include EsseConfig
end
