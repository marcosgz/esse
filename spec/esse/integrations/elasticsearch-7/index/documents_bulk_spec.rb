# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/index_documents_bulk'

stack_describe 'elasticsearch', '7.x', Esse::Index, '.bulk' do
  include_examples 'index.bulk'
end
