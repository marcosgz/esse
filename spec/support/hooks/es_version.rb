module Hooks
  # Allows to set the Elasticsearch version to be used in the tests using real
  module EsVersion
    def self.included(base)
      base.around(:example) do |example|
        if (version = example.metadata[:es_version])
          re = Regexp.new(Regexp.escape(version).gsub('x', '\d+'))
          if re.match(Elasticsearch::Transport::VERSION)
            if example.metadata[:es_webmock]
              WebMock.disable_net_connect!(allow_localhost: false)
            else
              EsVersion.webmock_disable_all_except_elasticsearch_hosts!
            end
            example.run
          else
            example.metadata[:skip] = "requires ElasticSearch version #{version} to run (current version is #{Elasticsearch::Transport::VERSION})"
          end
        else
          example.run
        end
      end
    end

    def self.webmock_disable_all_except_elasticsearch_hosts!
      WebMock.allow_net_connect!
      WebMock.disable_net_connect!(allow: hosts)
    end

    private_class_method def self.hosts
      Esse.config.cluster_ids.flat_map do |cluster_id|
        Esse.config.cluster(cluster_id).client.transport.connections.map do |conn|
          uri = URI.parse(conn.full_url(''))
          [uri.hostname, uri.port].join(':')
        end
      end.uniq
    end
  end
end
