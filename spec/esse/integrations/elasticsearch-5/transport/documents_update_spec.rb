# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/transport_documents_update'

stack_describe 'elasticsearch', '5.x', Esse::Transport, '#update' do
  include_examples 'transport#update', doc_type: true
end
