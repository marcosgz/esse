# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/transport_documents_count'

stack_describe 'elasticsearch', '.x', Esse::Transport, '#count' do
  include_examples 'transport#count'
end
