# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/index_update_mapping'

stack_describe 'elasticsearch', '8.x', Esse::Index, '.update_mapping' do
  include_examples 'index.update_mapping'
end
