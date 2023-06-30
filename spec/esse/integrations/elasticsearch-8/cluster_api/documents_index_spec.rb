# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/cluster_api_documents_index'

stack_describe 'elasticsearch', '8.x', Esse::Transport, '#index' do
  include_examples 'cluster_api#index'
end
