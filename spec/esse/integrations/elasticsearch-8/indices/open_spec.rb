# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/index_open'

stack_describe 'elasticsearch', '8.x', Esse::Index, '.open' do
  include_examples 'index.open'
end
