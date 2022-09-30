# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/cluster_api_open'

stack_describe 'elasticsearch', '6.x', Esse::ClientProxy, '#open' do
  include_examples 'cluster_api#open'
end
