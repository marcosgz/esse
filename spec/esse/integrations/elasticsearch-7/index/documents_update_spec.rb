# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/index_documents_update'

stack_describe 'elasticsearch', '7.x', Esse::Index, '.update' do
  include_examples 'index.update'
end
