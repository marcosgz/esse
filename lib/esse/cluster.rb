# frozen_string_literal: true

module Esse
  class Cluster
    ATTRIBUTES = %i[index_prefix index_settings client].freeze

    # The index prefix. For example an index named UsersIndex.
    # With `index_prefix = 'app1'`. Final index/alias is: 'app1_users'
    attr_accessor :index_prefix

    # This settings will be passed through all indices during the mapping
    attr_accessor :index_settings

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
      @client ||= Elasticsearch::Client.new
    end

    # Define the elasticsearch client connectio
    # @param client [Elasticsearch::Client, Hash] an instance of elasticsearch/api client or an hash
    #   with the settings that will be used to initialize Elasticsearch::Client
    def client=(val)
      @client = if val.is_a?(Hash)
        settings = val.each_with_object({}) { |(k,v), r| r[k.to_sym] = v }
        Elasticsearch::Client.new(settings)
      else
        val
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
  end
end
