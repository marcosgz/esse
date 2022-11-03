# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/index_reset_index'

stack_describe 'elasticsearch', '7.x', Esse::Index, '.reset_index' do
  include_examples 'index.reset_index'
end
