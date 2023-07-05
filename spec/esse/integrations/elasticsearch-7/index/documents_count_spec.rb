# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/index_documents_count'

stack_describe 'elasticsearch', '7.x', Esse::Index, '.count' do
  include_examples 'index.count'
end
