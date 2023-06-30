# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/index_documents_index'

stack_describe 'elasticsearch', '8.x', Esse::Index, '.index' do
  include_examples 'index.index'
end
