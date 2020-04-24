# frozen_string_literal: true

module ElasticsearchHelpers
  CONFIG_KEY = Esse::Config::CLIENT_DEFAULT_KEY

  def wait_for_status(key: CONFIG_KEY, status: :green)
    return unless status

    with_config do |config|
      client = config.client(key)
      client.transport.reload_connections!
      client.cluster.health(wait_for_status: status)
      yield client, config if block_given?
    end
  end

  # Deletes all corresponding indexes with current prefix from ElasticSearch.
  # Be careful, if current prefix is blank, this will destroy all the indexes.
  def delete_all_indices!(key: CONFIG_KEY, pattern: '*')
    with_config do |config|
      client = config.client(key)
      client.indices.delete(index: [config.index_prefix, pattern].compact.join('_'))
      yield client, config if block_given?
    end
  end
  alias es_client delete_all_indices!
end
