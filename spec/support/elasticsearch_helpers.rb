# frozen_string_literal: true

module ElasticsearchHelpers
  extend self

  CONFIG_KEY = Esse::Config::DEFAULT_CLUSTER_ID

  # Deletes all corresponding indices with current prefix from ElasticSearch.
  # Be careful, if current prefix is blank, this will destroy all the indices.
  def delete_all_indices!(key: CONFIG_KEY, pattern: '*')
    with_config do |config|
      cluster = config.cluster(key)
      Hooks::ServiceVersion.webmock_disable_all_except_elasticsearch_hosts!(cluster)
      cluster.client.indices.delete(index: [cluster.index_prefix, pattern].compact.join('_'))
      cluster.wait_for_status!(status: :green)
      yield cluster.client, config, cluster if block_given?
      cluster.remove_instance_variable(:@request_params) if cluster.instance_variable_defined?(:@request_params)
      cluster.remove_instance_variable(:@request_body) if cluster.instance_variable_defined?(:@request_body)
    end
  end
  alias_method :es_client, :delete_all_indices!

  # @option [String] :distribution ('elasticsearch') The name of the service to connect to. Valid values are 'elasticsearch' and 'opensearch'.
  def elasticsearch_response_fixture(file:, version:, assigns: {}, distribution: 'elasticsearch', **)
    dirname = File.expand_path("../../fixtures/#{distribution}-response/#{version}", __FILE__)
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
    res[:headers] ||= {
      'Content-Type' => 'application/json',
    }
    # elasticsearch-ruby >= 8.0 throws Elasticsearch::UnsupportedProductError if the response
    # doesn't include the 'x-elastic-product' header
    res[:headers]['x-elastic-product'] ||= 'Elasticsearch'

    uri = es_cluster_uri
    uri.path = path
    uri.query = URI.encode_www_form(params) if params.any?
    stub_request(verb, uri.to_s).to_return(res)
  end

  def es_cluster_uri(cluster_id = CONFIG_KEY)
    client = Esse.config.cluster(cluster_id).client
    # OpenSearch have an initial request to verify the client compatibility
    client.instance_variable_set(:@verified, true)
    transport = client.transport
    transport = transport.transport if transport.respond_to?(:transport)
    conn = transport.connections.first
    URI.parse(conn.full_url(''))
  end
end
