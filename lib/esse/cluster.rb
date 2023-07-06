# frozen_string_literal: true

require_relative 'cluster_engine'
require_relative 'transport'

module Esse
  class Cluster
    ATTRIBUTES = %i[index_prefix settings mappings client wait_for_status readonly].freeze
    WAIT_FOR_STATUSES = %w[green yellow red].freeze

    # The index prefix. For example an index named UsersIndex.
    # With `index_prefix = 'app1'`. Final index/alias is: 'app1_users'
    attr_accessor :index_prefix

    # This global settings will be passed through all indices
    attr_accessor :settings

    # This global mappings will be applied to all indices
    # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html
    attr_accessor :mappings

    # if this option set, actions such as creating or deleting index,
    # importing data will wait for the status specified. Extremely useful
    # for tests under heavy indices manipulations.
    # Value can be set to `red`, `yellow` or `green`.
    #
    # Example:
    #   wait_for_status: green
    attr_accessor :wait_for_status

    # Disable all writes from the application to the underlying Elasticsearch instance while keeping the
    # application running and handling search requests.
    attr_writer :readonly

    attr_reader :id

    def initialize(id:, **options)
      @id = id.to_sym
      @settings = {}
      @mappings = {}
      @readonly = false
      assign(options)
    end

    def assign(hash)
      return unless hash.is_a?(Hash)

      hash.each do |key, value|
        method = (ATTRIBUTES & [key.to_s, key.to_sym]).first
        next unless method

        public_send(:"#{method}=", value)
      end
    end

    def client
      @client ||= if defined? Elasticsearch::Client
        Elasticsearch::Client.new
      elsif defined? OpenSearch::Client
        OpenSearch::Client.new
      else
        raise Esse::Error, <<~ERROR
          Elasticsearch::Client or OpenSearch::Client is not defined.
          Please install elasticsearch or opensearch-ruby gem.
        ERROR
      end
    end

    # @return [Boolean] Return true if the cluster is readonly
    def readonly?
      !!@readonly
    end

    # @raise [Esse::Transport::ReadonlyClusterError] if the cluster is readonly
    # @return [void]
    def throw_error_when_readonly!
      raise Esse::Transport::ReadonlyClusterError if readonly?
    end

    # Define the elasticsearch client connection
    # @param es_client [Elasticsearch::Client, OpenSearch::Client, Hash] an instance of elasticsearch/api client or an hash
    #   with the settings that will be used to initialize the Client
    def client=(es_client)
      @client = if es_client.is_a?(Hash) && defined?(Elasticsearch::Client)
        settings = es_client.each_with_object({}) { |(k, v), r| r[k.to_sym] = v }
        Elasticsearch::Client.new(settings)
      elsif es_client.is_a?(Hash) && defined?(OpenSearch::Client)
        settings = es_client.each_with_object({}) { |(k, v), r| r[k.to_sym] = v }
        OpenSearch::Client.new(settings)
      else
        es_client
      end
    end

    def inspect
      attrs = ([:id] + ATTRIBUTES - [:client, :readonly]).map do |method|
        value = public_send(method)
        format('%<k>s=%<v>p', k: method, v: value) if value
      end.compact
      attrs << 'readonly=true' if readonly?
      attrs << format('client=%p', @client)
      format('#<Esse::Cluster %<attrs>s>', attrs: attrs.join(' '))
    end

    # Wait until cluster is in a specific state
    #
    # @option [String] :status Wait until cluster is in a specific state (options: green, yellow, red)
    # @option [String] :index Limit the information returned to a specific index
    def wait_for_status!(status: nil, **kwargs)
      status ||= wait_for_status
      return unless WAIT_FOR_STATUSES.include?(status.to_s)

      api.health(**kwargs, wait_for_status: status.to_s)
    end

    # @idea Change this to use the response from `GET /`
    def document_type?
      return false if engine.mapping_single_type?

      (defined?(OpenSearch::VERSION) && OpenSearch::VERSION < '2') || \
        (defined?(Elasticsearch::VERSION) && Elasticsearch::VERSION < '7')
    end

    def info
      @info ||= begin
        resp = client.info
        {
          distribution: (resp.dig('version', 'distribution') || 'elasticsearch'),
          version: resp.dig('version', 'number'),
        }
      end
    end

    def engine
      @engine ||=ClusterEngine.new(**info)
    end
    alias_method :warm_up!, :engine

    # Build a search query for the given indices
    #
    # @param indices [Array<Esse::Index, String>] The indices class or the index name
    # @return [Esse::Search::Query] The search query instance
    def search(*indices, **kwargs, &block)
      Esse::Search::Query.new(api, *indices, **kwargs, &block)
    end

    # Return the proxy object used to perform low level actions on the elasticsearch cluster through the official api client
    #
    # @return [Esse::Transport] The cluster api instance
    def api
      Esse::Transport.new(self)
    end
  end
end
