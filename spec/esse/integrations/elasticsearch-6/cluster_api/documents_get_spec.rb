# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/cluster_api_documents_get'

stack_describe 'elasticsearch', '6.x', Esse::Transport, '#get' do
  include_examples 'cluster_api#get', doc_type: true
end
