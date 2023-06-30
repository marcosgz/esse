# frozen_string_literal: true

module Esse
  module Deprecations
    module Deprecate
      def self.extended(base)
        base.extend Gem::Deprecate
        base.include InstanceMethods
      end

      module InstanceMethods
        def warning(method, repl, year, month)
          msg = ["NOTE: #{method} is deprecated"]
          msg << if repl == :none
            ' with no replacement'
          elsif repl.respond_to?(:call)
            "; use #{repl.call} instead"
          else
            "; use #{repl} instead"
          end
          msg << '. It will be removed on or after %4d-%02d-01.' % [year, month]
          msg << "\n#{method} called from #{Gem.location_of_caller(2).join(':')}"

          warn "#{msg.join}." unless Gem::Deprecate.skip
        end
      end
    end
  end
end
