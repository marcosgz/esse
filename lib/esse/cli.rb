# frozen_string_literal: true

require 'thor'

require_relative 'primitives/output'
require_relative 'cli/index'
require_relative 'cli/generate'
require_relative 'cli/event_listener'

module Esse
  module CLI
    class << self
      def start(*args)
        Root.start(*args)
      end

      def with_friendly_errors
        yield
      rescue CLI::Error => e
        Output.print_error(e)
        exit(1)
      end
    end

    class Root < Thor
      include Thor::Actions

      class_option :require, type: :string, aliases: '-r', required: false,
        default: nil, desc: 'Require config file where the application is defined'
      class_option :silent, type: :boolean, aliases: '-s', required: false, default: false, desc: 'Silent mode'

      def initialize(*)
        super

        load_app_config(options[:require])
        setup_listeners if !options[:silent] && Esse.config.cli_event_listeners?
      end

      def self.source_root
        File.expand_path('../cli', __FILE__)
      end

      def self.exit_on_failure?
        true
      end

      map %w[--version -v] => :version

      desc 'index SUBCOMMAND ...ARGS', 'Manage indices'
      subcommand 'index', Index

      desc 'generate SUBCOMMAND ...ARGS', 'Run generators'
      subcommand 'generate', Generate

      desc '--version, -v', 'Show package version'
      def version
        Output.print_message('Esse version: %<version>s', version: Esse::VERSION)
      end

      desc 'install', 'Generate boilerplate configuration files'
      option :path, type: :string, aliases: '-p', required: false, default: './'
      def install
        path = Pathname.new(File.expand_path(options[:path], Dir.pwd))
        path = path.dirname unless path.directory?
        @app_dir = path.basename
        template(
          'templates/config.rb.erb',
          path.join('config/esse.rb'),
        )
      end

      private

      def setup_listeners
        Esse::Events.__bus__.events.keys.grep(/^elasticsearch/).each do |event_name|
          Esse::Events.subscribe(event_name) do |event|
            EventListener[event_name]&.call(event)
          end
        end
      end

      def load_app_config(path)
        if path.nil?
          CLI_CONFIG_PATHS.each do |config_path|
            next unless File.exist?(config_path)
            path = config_path
            break
          end
        end
        return unless path

        begin
          Output.print_message('Loading configuration file: %<path>s', path: path)
          load path
        rescue LoadError => e
          raise InvalidOption, e.message
        end
      end
    end
  end
end
