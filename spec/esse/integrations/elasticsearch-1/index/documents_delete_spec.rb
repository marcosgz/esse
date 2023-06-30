# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/index_documents_delete'

stack_describe 'elasticsearch', '1.x', Esse::Index, '.delete' do
  include_examples 'index.delete', doc_type: true
end
