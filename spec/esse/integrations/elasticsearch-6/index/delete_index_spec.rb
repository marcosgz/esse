# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/index_delete_index'

stack_describe 'elasticsearch', '6.x', Esse::Index, '.delete_index' do
  include_examples 'index.delete_index'
end
