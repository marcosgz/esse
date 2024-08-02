# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/index_documents_update_by_query'

stack_describe 'elasticsearch', '7.x', Esse::Index, '.update_by_query' do
  include_examples 'index.update_by_query'
end
