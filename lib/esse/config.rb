# frozen_string_literal: true

require 'pathname'

module Esse
  # Provides all configurations
  #
  # Example
  #   Esse.config do |conf|
  #     conf.client = Elasticsearch::Client.new
  #     conf.index_prefix = 'backend'
  #     conf.index_settings = {
  #       number_of_shards: 2,
  #       number_of_replicas: 0
  #     }
  #   end
  class Config
    CLIENT_DEFAULT_KEY = :_default
    SETUP_ATTRIBUTES = %i[index_prefix index_settings indices_directory].freeze

    # The index prefix. For example an index named UsersIndex.
    # With `index_prefix = 'app1'`. Final index/alias is: 'app1_users'
    attr_accessor :index_prefix

    # This settings will be passed through all indices during the mapping
    attr_accessor :index_settings

    # The location of the indices. Defaults to the `app/indices`
    attr_reader :indices_directory

    def initialize
      @clients = {}
      @index_settings = {}
      self.indices_directory = 'app/indices'
    end

    def client(key = CLIENT_DEFAULT_KEY)
      @clients[key] ||= Elasticsearch::Client.new
    end

    # It's possible to define multiple elasticsearch clients.
    # For example if your application is using two versions of es.
    # Client definition could be something like:
    #
    #   Esse.config.client = {
    #     v5: Elasticsearch::Client.new(url: 'v5.example.com:9200'),
    #     v6: Elasticsearch::Client.new(url: 'v6.example.com:9200')
    #   }
    def client=(val)
      case val
      when Hash
        @clients.merge!(val)
      else
        @clients[CLIENT_DEFAULT_KEY] = val
      end
    end

    def indices_directory=(value)
      @indices_directory = value.is_a?(Pathname) ? value : Pathname.new(value)
    end

    def setup(hash)
      return unless hash.is_a?(Hash)

      hash.each do |key, value|
        next unless SETUP_ATTRIBUTES.include? key.to_sym

        public_send(:"#{key}=", value)
      end
    end
  end
end
