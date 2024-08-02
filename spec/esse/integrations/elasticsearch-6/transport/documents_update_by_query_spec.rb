# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/transport_update_by_query'

stack_describe 'elasticsearch', '6.x', Esse::Transport, '#update_by_query' do
  include_examples 'transport#update_by_query', doc_type: true
end
