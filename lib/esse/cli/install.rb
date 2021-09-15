# frozen_string_literal: true

require 'thor'
require_relative 'base'

module Esse
  module CLI
    class Install < Base
      default_task :default

      def self.source_root
        File.dirname(__FILE__)
      end

      option :path, type: :string, aliases: '-p', required: false, default: './'
      def default
        path = Pathname.new(File.expand_path(options[:path], Dir.pwd))
        @app_name = path.dirname
        template(
          'templates/config.rb.erb',
          path.join("config/esse.rb"),
        )
      end
    end
  end
end
