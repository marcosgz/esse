# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/index_indices_pointing_to_alias'

stack_describe 'elasticsearch', '8.x', Esse::Index, '.indices_pointing_to_alias' do
  include_examples 'index.indices_pointing_to_alias'
end
