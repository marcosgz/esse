# frozen_string_literal: true

require 'pathname'
require 'yaml'
require 'json'

module Esse
  class TemplateLoader
    EXT_PARSER = {
      'json' => ->(file) { MultiJson.load(File.read(file)) },
      'yaml' => ->(file) { YAML.load_file(file) },
      'yml' => ->(file) { YAML.load_file(file) },
    }.freeze

    def initialize(directories, extensions: EXT_PARSER.keys)
      @directories = Array(directories).map do |dir|
        dir.is_a?(Pathname) ? dir : Pathname.new(dir)
      end
      @extensions = extensions
    end

    # Look for files into the @directories using some file pattern.
    def read(*patterns)
      path = nil
      @directories.each do |dir|
        patterns.find do |pattern|
          path = Dir[dir.join("#{pattern}.{#{@extensions.join(',')}}")].first
          break if path
        end
        break if path
      end
      load(path) if path
    end

    protected

    def load(file)
      parser = EXT_PARSER[File.extname(file).sub(/^\./, '')]
      return unless parser

      parser.call(file)
    rescue MultiJson::ParseError
      nil
    end
  end
end
