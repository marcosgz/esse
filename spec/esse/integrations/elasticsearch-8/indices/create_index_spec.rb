# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/index_create_index'

stack_describe 'elasticsearch', '8.x', Esse::Index, '.create_index' do
  include_examples 'index.create_index'
end
