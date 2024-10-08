# frozen_string_literal: true

module Esse
  require_relative 'config'
  require_relative 'cluster'
  require_relative 'primitives'
  require_relative 'collection'
  require_relative 'document'
  require_relative 'document_for_partial_update'
  require_relative 'document_lazy_attribute'
  require_relative 'lazy_document_header'
  require_relative 'hash_document'
  require_relative 'null_document'
  require_relative 'repository'
  require_relative 'index_setting'
  require_relative 'dynamic_template'
  require_relative 'index_mapping'
  require_relative 'template_loader'
  require_relative 'import/request_body'
  require_relative 'import/bulk'
  require_relative 'version'
  require_relative 'logging'
  require_relative 'events'
  require_relative 'search/query'
  require_relative 'search/response'
  require_relative 'deprecations' # Should be last
  include Logging

  @single_threaded = false
  # Mutex used to protect mutable data structures
  @data_mutex = Mutex.new

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
  # @param hash [Hash] the JSON document
  # @param delete [Array] Removes the hash key and return its value
  # @param keep [Array] Fetch the hash key and return its value
  # @return [Array([Integer, String, nil], Hash)] return the key value and the modified hash
  def self.doc_id!(hash, delete: %w[_id], keep: %w[id])
    return unless hash.is_a?(Hash)

    id = nil
    modified = nil
    Array(delete).each do |key|
      k = key.to_s if hash.key?(key.to_s)
      k ||= key.to_sym if hash.key?(key.to_sym)
      next unless k

      modified ||= hash.dup
      id = modified.delete(k)
      break if id
    end
    return [id, modified] if id

    modified ||= hash
    Array(keep).each do |key|
      id = modified[key.to_s] || modified[key.to_sym]
      break if id
    end
    [id, modified]
  end

  def self.eager_load_indices!
    return false unless Esse.config.indices_directory.exist?

    Dir[Esse.config.indices_directory.join('**/*_index.rb')].map { |path| Pathname.new(path) }.each do |path|
      next unless path.extname == '.rb'

      require(path.expand_path.to_s)
    end
    true
  end

  def self.document?(object)
    return false unless object

    !!(object.is_a?(Esse::Document) && object.id)
  end

  def self.document_match_with_header?(document, id, routing, type)
    id && id.to_s == document.id.to_s &&
      routing == document.routing &&
      (LazyDocumentHeader::ACCEPTABLE_DOC_TYPES.include?(document.type) && LazyDocumentHeader::ACCEPTABLE_DOC_TYPES.include?(type) || document.type == type)
  end
end
