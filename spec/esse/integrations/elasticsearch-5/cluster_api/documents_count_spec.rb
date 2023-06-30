# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/cluster_api_documents_count'

stack_describe 'elasticsearch', '5.x', Esse::Transport, '#count' do
  include_examples 'cluster_api#count', doc_type: true
end
