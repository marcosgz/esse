# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/transport_documents_mget'

stack_describe 'elasticsearch', '5.x', Esse::Transport, '#mget' do
  include_examples 'transport#mget', doc_type: true
end
