# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/index_open'

stack_describe 'elasticsearch', '5.x', Esse::Index, '.open' do
  include_examples 'index.open'
end
