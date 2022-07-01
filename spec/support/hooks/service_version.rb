module Hooks
  # Allows to set the Elasticsearch version to be used in the tests using real
  module ServiceVersion
    def self.included(base)
      base.around(:example) do |example|
        if example.metadata[:es_version] && ENV['STUB_STACK']
          skip("Skipping because STUB_STACK is set to #{ENV['STUB_STACK'].inspect}")
        elsif (version = example.metadata[:es_version])
          version_number = ServiceVersion.stats.version_number
          if ServiceVersion.stats.version_distribution == 'opensearch'
            version_number = Esse::ClusterEngine::OPENSEARCH_FORK_VERSION
          end
          re = Regexp.new('^' + Regexp.escape(version).gsub('x', '\d+'))
          if re.match(version_number)
            WebMock.disable_net_connect!(allow_localhost: false)
            example.run
          else
            skip("requires elasticsearch version #{version} to run (current version is #{version_number})")
          end
        else
          example.run
        end
      end
    end

    def self.stats
      return @stats if defined? @stats

      body = if (stats = ENV['STUB_STACK'])
        distribution, version = stats.split('-', 2)
        ElasticsearchHelpers.elasticsearch_response_fixture(file: 'info', version: "#{version.to_i}.x", distribution: distribution, assigns: { version__number: version })
      else
        url = ENV['ESSE_URL'] || ENV['ELASTICSEARCH_URL'] || ENV['OPENSEARCH_URL'] || 'http://localhost:9200'
        conn = Faraday.new(url: url, ssl: { verify: false }, request: { timeout: 5 }, headers: { 'Content-Type' => 'application/json' })
        resp = conn.get('/')
        raise "Elasticsearch is not running on #{url}" unless resp.success?
        resp.body
      end

      parse_stats_response(MultiJson.load(body))
    end

    def self.banner!
      max_key = Hooks::ServiceVersion.stats.to_h.keys.map(&:to_s).max_by(&:size).size
      max_val = Hooks::ServiceVersion.stats.to_h.values.map(&:to_s).max_by(&:size).size
      puts ' ElasticSearch Server Information '.center(max_key + max_val + 7, '=')
      Hooks::ServiceVersion.stats.to_h.each do |k, v|
        puts "= #{k.to_s.ljust(max_key)} : #{v.to_s.ljust(max_val)} ="
      end
      puts '=' * (max_key + max_val + 7)
    rescue
      puts 'ElasticSearch Server is not running'
      exit(1)
    end

    def self.webmock_disable_all_except_elasticsearch_hosts!(*clusters)
      WebMock.allow_net_connect!
      clusters = Esse.config.cluster_ids.map { |id| Esse.config.cluster(id) } if clusters.empty?
      WebMock.disable_net_connect!(allow: cluster_hosts(clusters))
    end

    private_class_method def self.parse_stats_response(json)
      inline_attributes = json.each_with_object({}) do |(k, v), h|
        if v.is_a?(Hash)
          v.each { |k2, v2| h["#{k}_#{k2}"] = v2 }
        else
          h[k] = v
        end
      end

      @stats = OpenStruct.new(inline_attributes)
    end

    private_class_method def self.cluster_hosts(clusters)
      clusters.flat_map do |cluster|
        transport = cluster.client.transport
        transport = transport.transport if transport.respond_to?(:transport)
        transport.connections.map do |conn|
          uri = URI.parse(conn.full_url(''))
          [uri.hostname, uri.port].join(':')
        end
      end.uniq
    end
  end
end
