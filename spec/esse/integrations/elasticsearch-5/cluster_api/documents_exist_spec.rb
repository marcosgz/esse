# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/cluster_api_documents_exist'

stack_describe 'elasticsearch', '5.x', Esse::Transport, '#exist?' do
  include_examples 'cluster_api#exist?', doc_type: true
end
