# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/index_documents_get'
require 'support/shared_examples/index_documents_get_with_routing'

stack_describe 'elasticsearch', '5.x', Esse::Index, '.get' do
  include_examples 'index.get'
  include_examples 'index.get with routing'
end
