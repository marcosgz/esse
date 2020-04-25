# frozen_string_literal: true

require 'multi_json'
require 'elasticsearch'

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

  # Generates an unique timestamp to be used as a index suffix.
  # Time.now.to_i could also do the job. But I think this format
  # is more readable for humans
  def self.timestamp
    Time.now.strftime('%Y%m%d%H%M%S')
  end

  # Simple helper used to fetch Hash value using Symbol and String keys.
  #
  # @param [Hash] the JSON document
  # @option [Array] :delete Removes the hash key and return its value
  # @option [Array] :keep Fetch the hash key and return its value
  # @return [Array([Integer, String, nil], Hash)] return the key value and the modified hash
  def self.doc_id!(hash, delete: %w[_id], keep: %w[id])
    return unless hash.is_a?(Hash)

    id, modified = [nil, nil]
    Array(delete).each do |key|
      k = key.to_s if hash.key?(key.to_s)
      k ||= key.to_sym if hash.key?(key.to_sym)
      if k
        modified ||= hash.dup
        id = modified.delete(k)
        break if id
      end
    end
    return [id, modified] if id

    modified ||= hash
    Array(keep).each do |key|
      id = modified[key.to_s] || modified[key.to_sym]
      break if id
    end
    [id, modified]
  end

  require_relative 'config'
  require_relative 'primitives'
  require_relative 'index_type'
  require_relative 'index_setting'
  require_relative 'index_mapping'
  require_relative 'template_loader'
  require_relative 'backend/index'
  require_relative 'backend/index_type'
  require_relative 'version'
end
