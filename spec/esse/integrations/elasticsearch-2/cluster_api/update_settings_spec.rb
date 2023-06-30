# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/cluster_api_update_settings'

stack_describe 'elasticsearch', '2.x', Esse::Transport, '#update_settings' do
  include_examples 'cluster_api#update_settings'
end
