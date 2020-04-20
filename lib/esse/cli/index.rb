# frozen_string_literal: true

require 'thor'
require_relative 'base'
module Esse
  module CLI
    class Index < Base
      desc 'create *INDEX_CLASSES', 'Creates a new index'
      def create(*index_classes)
        # Add action here
      end
    end
  end
end
