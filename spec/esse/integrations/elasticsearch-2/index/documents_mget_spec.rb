# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/index_documents_mget'

stack_describe 'elasticsearch', '2.x', Esse::Index, '.mget' do
  include_examples 'index.mget'
end
