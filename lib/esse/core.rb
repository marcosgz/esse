# frozen_string_literal: true

require 'elasticsearch/transport'

module Esse
  # Block configurations
  #   Esse.config do |conf|
  #     conf.client = Elasticsearch::Client.new
  #     conf.index_prefix = 'backend'
  #     conf.index_settings = {
  #       number_of_shards: 2,
  #       number_of_replicas: 0
  #     }
  #   end
  #
  # Inline configurations
  #   Esse.config.index_prefix = 'backend'
  #   Esse.config.client = Elasticsearch::Client.new
  def self.config
    @config ||= Config.new
    yield(@config) if block_given?
    @config
  end
end
