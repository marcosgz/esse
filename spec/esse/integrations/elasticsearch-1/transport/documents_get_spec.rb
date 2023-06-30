# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/transport_documents_get'

stack_describe 'elasticsearch', '1.x', Esse::Transport, '#get' do
  include_examples 'transport#get', doc_type: true
end
