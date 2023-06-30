# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/cluster_api_refresh'

stack_describe 'elasticsearch', '2.x', Esse::Transport, '#refresh' do
  include_examples 'cluster_api#refresh'
end
