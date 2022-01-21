# frozen_string_literal: true

require 'pathname'

module Esse
  # Block configurations
  #   Esse.configure do |conf|
  #     conf.indices_directory = 'app/indices/directory'
  #     conf.clusters(:v1) do |cluster|
  #       cluster.index_prefix = 'backend'
  #       cluster.client = Elasticsearch::Client.new
  #       cluster.index_settings = {
  #         number_of_shards: 2,
  #         number_of_replicas: 0
  #       }
  #     end
  #   end
  #
  # Inline configurations
  #   Esse.config.indices_directory = 'app/indices/directory'
  #   Esse.config.clusters(:v1).client = Elasticsearch::Client.new
  class << self
    def config
      @config ||= Config.new
      yield(@config) if block_given?
      @config
    end
    alias_method :configure, :config
  end

  # Provides all configurations
  #
  # Example
  #   Esse.config do |conf|
  #     conf.indices_directory = 'app/indices'
  #   end
  class Config
    DEFAULT_CLUSTER_ID = :default
    ATTRIBUTES = %i[indices_directory].freeze

    # The location of the indices. Defaults to the `app/indices`
    attr_reader :indices_directory

    def initialize
      self.indices_directory = 'app/indices'
      @clusters = {}
      clusters(DEFAULT_CLUSTER_ID) # initialize the :default client
    end

    def cluster_ids
      @clusters.keys
    end

    def clusters(key = DEFAULT_CLUSTER_ID, **options)
      return unless key

      id = key.to_sym
      (@clusters[id] ||= Cluster.new(id: id)).tap do |c|
        c.assign(options) if options
        yield c if block_given?
      end
    end

    def indices_directory=(value)
      @indices_directory = value.is_a?(Pathname) ? value : Pathname.new(value)
    end

    def load(arg)
      case arg
      when Hash
        assign(arg)
      when File, Pathname
        # @TODO Load JSON or YAML
      when String
        # @TODO Load JSON or YAML if File.exist?(arg)
      else
        raise ArgumentError, printf('could not load configuration using: %p', val)
      end
    end

    # :nodoc:
    # This is only used by rspec to disable the CLI print out.
    def cli_event_listeners?
      true
    end

    private

    def assign(hash)
      hash.each do |key, value|
        method = (ATTRIBUTES & [key.to_s, key.to_sym]).first
        next unless method

        public_send("#{method}=", value)
      end
      if (connections = hash['clusters'] || hash[:clusters]).is_a?(Hash)
        connections.each do |key, value|
          clusters(key).assign(value) if value.is_a?(Hash)
        end
      end
      true
    end
  end
end
