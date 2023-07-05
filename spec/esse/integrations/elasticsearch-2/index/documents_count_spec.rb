# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/index_documents_count'

stack_describe 'elasticsearch', '2.x', Esse::Index, '.count' do
  include_examples 'index.count', doc_type: true
end
