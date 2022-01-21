# frozen_string_literal: true

module ElasticsearchHelpers
  CONFIG_KEY = Esse::Config::DEFAULT_CLUSTER_ID

  # Deletes all corresponding indices with current prefix from ElasticSearch.
  # Be careful, if current prefix is blank, this will destroy all the indices.
  def delete_all_indices!(key: CONFIG_KEY, pattern: '*')
    with_config do |config|
      cluster = config.cluster(key)
      cluster.client.indices.delete(index: [cluster.index_prefix, pattern].compact.join('_'))
      cluster.wait_for_status!(status: :green)
      yield cluster.client, config, cluster if block_given?
    end
  end
  alias_method :es_client, :delete_all_indices!

  def elasticsearch_response_fixture(file:, version:, assigns: {}, **)
    dirname = File.expand_path("../../fixtures/elasticsearch-response/#{version}", __FILE__)
    path = nil
    [file, "#{file}.json", "#{file}.json.erb"].each do |filename|
      path = File.join(dirname, filename)
      break if File.exist?(path)
    end

    raise "No elasticsearch response fixture found for #{file} in #{dirname}" unless path

    case File.extname(path)
    when '.erb'
      template = File.read(path)
      ERB.new(template).result_with_hash(assigns: assigns)
    else
      File.read(path)
    end
  end

  def stub_es_request(verb, path, params: {}, req: {}, res: {})
    res[:status] ||= 200
    res[:body] ||= { acknowledged: true }
    res[:body] = MultiJson.dump(res[:body]) unless res[:body].is_a?(String)

    uri = es_cluster_uri
    uri.path = path
    uri.query = URI.encode_www_form(params) if params.any?
    stub_request(verb, uri.to_s).to_return(res)
  end

  def es_cluster_uri(cluster_id = CONFIG_KEY)
    conn = Esse.config.cluster(cluster_id).client.transport.connections.first
    URI.parse(conn.full_url(''))
  end
end
