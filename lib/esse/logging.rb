require 'logger'

module Esse
  module Logging
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def logger
        @logger ||= ::Logger.new($stdout)
      end

      def logger=(log)
        @logger = log || ::Logger.new(File::NULL)
      end
    end
  end
end
