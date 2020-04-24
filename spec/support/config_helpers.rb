# frozen_string_literal: true

module ConfigHelpers
  DEFAULTS = {
    index_prefix: 'esse_test',
    indices_directory: 'tmp/indices',
    index_settings: {
      number_of_shards: 1,
      number_of_replicas: 0,
    },
  }.freeze

  def reset_config!
    Esse::Index.elasticsearch_client = nil
    Esse.instance_variable_set(:@config, nil)
  end

  def with_config(opts = {})
    settings = DEFAULTS.dup.merge(opts)
    Esse.config.setup(settings)

    yield Esse.config

    reset_config!
  end
end
