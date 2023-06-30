# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/cluster_api_update_aliases'

stack_describe 'elasticsearch', '5.x', Esse::Transport, '#update_aliases' do
  include_examples 'cluster_api#update_aliases'
end
