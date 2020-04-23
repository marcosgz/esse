# frozen_string_literal: true

require 'elasticsearch/transport'

module Esse
  @single_threaded = false
  # Mutex used to protect mutable data structures
  @data_mutex = Mutex.new

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

  # Unless in single threaded mode, protects access to any mutable
  # global data structure in Esse.
  # Uses a non-reentrant mutex, so calling code should be careful.
  # In general, this should only be used around the minimal possible code
  # such as Hash#[], Hash#[]=, Hash#delete, Array#<<, and Array#delete.
  def self.synchronize(&block)
    @single_threaded ? yield : @data_mutex.synchronize(&block)
  end

  require_relative 'config'
  require_relative 'primitives'
  require_relative 'index_type'
  require_relative 'index_setting'
  require_relative 'types'
  require_relative 'template_loader'
  require_relative 'version'
end
