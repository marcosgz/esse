module Hooks
  # Allows to set the Elasticsearch version to be used in the tests using real
  module EsVersion
    def self.included(base)
      base.around(:example) do |example|
        if (version = example.metadata[:es_version])
          re = Regexp.new(Regexp.escape(version).gsub('x', '\d+'))
          if re.match(Elasticsearch::Transport::VERSION)
            EsVersion.disable_webmock_for_es! if [nil, false].include?(example.metadata[:webmock])
            example.run
          else
            skip "Elasticsearch version #{version} required"
          end
        else
          example.run
        end
      end
    end

    def self.disable_webmock_for_es!
      WebMock.allow_net_connect!
      WebMock.disable_net_connect!(allow: hosts)
    end

    private_class_method def self.hosts
      Esse.config.cluster_ids.flat_map do |cluster_id|
        Esse.config.clusters(cluster_id).client.transport.connections.map do |conn|
          uri = URI.parse(conn.full_url(''))
          [uri.hostname, uri.port].join(':')
        end
      end.uniq
    end
  end
end
