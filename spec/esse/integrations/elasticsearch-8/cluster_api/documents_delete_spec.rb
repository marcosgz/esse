# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/cluster_api_documents_delete'

stack_describe 'elasticsearch', '8.x', Esse::ClientProxy, '#delete' do
  include_examples 'cluster_api#delete'
end
