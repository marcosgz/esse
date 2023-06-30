# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/cluster_api_documents_exist'

stack_describe 'elasticsearch', '8.x', Esse::Transport, '#exist?' do
  include_examples 'cluster_api#exist?'
end
