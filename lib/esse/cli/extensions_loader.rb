# frozen_string_literal: true

module Esse
  module CLI
    class ExtensionsLoader
      GEMS = %w[
        esse-rails
        esse-active_record
        esse-sequel
        esse-kaminari
        esse-pagy
        esse-will_paginate
        esse-jbuilder
        esse-redis_storage
        esse-async_indexing
      ].freeze

      def self.load!
        GEMS.each do |gem_name|
          Kernel.require(gem_name)
        rescue LoadError
          # do nothing
        end
      end
    end
  end
end
