# frozen_string_literal: true

require 'thor'

require_relative 'cli/index'
require_relative 'cli/generate'

module Esse
  module CLI
    def self.start(*args)
      Root.start(*args)
    end

    class Root < Thor
      map %w[--version -v] => :version

      desc 'index SUBCOMMAND ...ARGS', 'Manage indices'
      subcommand 'index', Index

      desc 'generate SUBCOMMAND ...ARGS', 'Run generators'
      subcommand 'generate', Generate

      desc '--version, -v', 'Show package version'
      def version
        puts format('Esse version: %<version>s', version: Esse::VERSION)
      end
    end
  end
end
