# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/index_update_aliases'

stack_describe 'elasticsearch', '7.x', Esse::Index, '.update_aliases' do
  include_examples 'index.update_aliases'
end
