# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/index_documents_import'

stack_describe 'elasticsearch', '2.x', Esse::Index, '.import' do
  include_examples 'index.import'
end
