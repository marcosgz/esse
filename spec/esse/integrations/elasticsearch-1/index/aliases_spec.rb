# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/index_aliases'

stack_describe 'elasticsearch', '1.x', Esse::Index, '.aliases' do
  include_examples 'index.aliases'
end
