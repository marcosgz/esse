# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/cluster_api_health'

stack_describe 'elasticsearch', '8.x', Esse::Transport, '#health' do
  include_examples 'cluster_api#health'
end
