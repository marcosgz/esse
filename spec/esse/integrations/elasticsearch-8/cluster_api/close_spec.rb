# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/cluster_api_close'

stack_describe 'elasticsearch', '8.x', Esse::Transport, '#close' do
  include_examples 'cluster_api#close'
end
