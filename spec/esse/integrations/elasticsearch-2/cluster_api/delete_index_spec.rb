# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/cluster_api_delete_index'

stack_describe 'elasticsearch', '2.x', Esse::ClientProxy, '#delete_index' do
  include_examples 'cluster_api#delete_index'
end
