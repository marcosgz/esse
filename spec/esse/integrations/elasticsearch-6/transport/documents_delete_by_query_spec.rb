# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/transport_delete_by_query'

stack_describe 'elasticsearch', '6.x', Esse::Transport, '#delete_by_query' do
  include_examples 'transport#delete_by_query', doc_type: true
end
