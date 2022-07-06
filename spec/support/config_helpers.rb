# frozen_string_literal: true

module ConfigHelpers
  DEFAULTS = {
    indices_directory: 'tmp/indices',
    clusters: {
      default: {
        client: { url: ENV.fetch('ESSE_URL', ENV.fetch('ELASTICSEARCH_URL', 'http://localhost:9200')) },
        index_prefix: 'esse_test',
        index_settings: {
          number_of_shards: 1,
          number_of_replicas: 0,
        },
        index_mappings: {}
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

  def with_cluster_config(id: :default, **opts, &block)
    with_config { |c|
      c.cluster(id).assign(opts)
      block.call if block
    }
  end
end
