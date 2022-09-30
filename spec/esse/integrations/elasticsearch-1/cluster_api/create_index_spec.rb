# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/cluster_api_create_index'

stack_describe 'elasticsearch', '1.x', Esse::ClientProxy, '#create_index' do
  include_examples 'cluster_api#create_index'
end
