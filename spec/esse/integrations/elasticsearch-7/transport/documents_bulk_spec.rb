# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/transport_documents_bulk'

stack_describe 'elasticsearch', '7.x', Esse::Transport, '#bulk' do
  include_examples 'transport#bulk'
end
