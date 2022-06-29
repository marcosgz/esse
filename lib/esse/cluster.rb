# frozen_string_literal: true

module Esse
  class Cluster
    ATTRIBUTES = %i[index_prefix index_settings client wait_for_status].freeze
    WAIT_FOR_STATUSES = %w[green yellow red].freeze

    # The index prefix. For example an index named UsersIndex.
    # With `index_prefix = 'app1'`. Final index/alias is: 'app1_users'
    attr_accessor :index_prefix

    # This settings will be passed through all indices during the mapping
    attr_accessor :index_settings

    # if this option set, actions such as creating or deleting index,
    # importing data will wait for the status specified. Extremely useful
    # for tests under heavy indices manipulations.
    # Value can be set to `red`, `yellow` or `green`.
    #
    # Example:
    #   wait_for_status: green
    attr_accessor :wait_for_status

    attr_reader :id

    def initialize(id:, **options)
      @id = id.to_sym
      @index_settings = {}
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
      attrs = ([:id] + ATTRIBUTES - [:client]).map do |method|
        value = public_send(method)
        format('%<k>s=%<v>p', k: method, v: value) if value
      end.compact
      attrs << format('client=%p', @client)
      format('#<Esse::Cluster %<attrs>s>', attrs: attrs.join(' '))
    end

    def wait_for_status!(status: wait_for_status)
      return unless WAIT_FOR_STATUSES.include?(status.to_s)

      client.cluster.health(wait_for_status: status.to_s)
    end

    # @idea Change this to use the response from `GET /`
    def document_type?
      defined?(OpenSearch::VERSION) || \
        (defined?(Elasticsearch::VERSION) && Elasticsearch::VERSION < '7')
    end
  end
end
