# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/index_update_settings'

stack_describe 'elasticsearch', '2.x', Esse::Index, '.update_settings' do
  include_examples 'index.update_settings'
end
