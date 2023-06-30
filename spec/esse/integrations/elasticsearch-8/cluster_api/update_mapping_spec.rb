# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/cluster_api_update_mapping'

stack_describe 'elasticsearch', '8.x', Esse::Transport, '#update_mapping' do
  include_examples 'cluster_api#update_mapping'
end
