# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/transport_documents_delete'

stack_describe 'elasticsearch', '6.x', Esse::Transport, '#delete' do
  include_examples 'transport#delete', doc_type: true
end
