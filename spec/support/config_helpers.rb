# frozen_string_literal: true

module ConfigHelpers
  DEFAULTS = {
    indices_directory: 'tmp/indices',
    clusters: {
      default: {
        index_prefix: 'esse_test',
        index_settings: {
          number_of_shards: 1,
          number_of_replicas: 0,
        },
      },
    },
  }.freeze

  def reset_config!
    Esse::Index.cluster_id = nil
    Esse.instance_variable_set(:@config, nil)
  end

  def with_config(opts = {})
    settings = DEFAULTS.dup.merge(opts)
    Esse.config.load(settings)

    yield Esse.config

    reset_config!
  end

  def with_cluster_config(id: :default, **opts)
    with_config { |c| c.clusters(id).assign(**opts) }
  end
end
