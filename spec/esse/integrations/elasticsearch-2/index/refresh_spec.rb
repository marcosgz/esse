# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/index_refresh'

stack_describe 'elasticsearch', '2.x', Esse::Index, '.refresh' do
  include_examples 'index.refresh'
end
