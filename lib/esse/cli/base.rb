# frozen_string_literal: true

require 'thor'

module Esse
  module CLI
    class Base < Thor
      include Thor::Actions
    end
  end
end
