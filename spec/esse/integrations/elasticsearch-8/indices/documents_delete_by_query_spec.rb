# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/index_documents_delete_by_query'

stack_describe 'elasticsearch', '8.x', Esse::Index, '.delete_by_query' do
  include_examples 'index.delete_by_query'
end
