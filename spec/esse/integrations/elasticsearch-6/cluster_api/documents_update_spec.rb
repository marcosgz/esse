# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/cluster_api_documents_update'

stack_describe 'elasticsearch', '6.x', Esse::ClientProxy, '#update' do
  include_examples 'cluster_api#update'
end
