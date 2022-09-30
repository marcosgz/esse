# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/index_close'

stack_describe 'elasticsearch', '6.x', Esse::Index, '.close' do
  include_examples 'index.close'
end
