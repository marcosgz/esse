# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/transport_documents_index'

stack_describe 'elasticsearch', '7.x', Esse::Transport, '#index' do
  include_examples 'transport#index'
end
