# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/transport_documents_count'

stack_describe 'elasticsearch', '1.x', Esse::Transport, '#count' do
  include_examples 'transport#count', doc_type: true
end
