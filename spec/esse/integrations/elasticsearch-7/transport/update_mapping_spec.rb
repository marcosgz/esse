# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/transport_update_mapping'

stack_describe 'elasticsearch', '7.x', Esse::Transport, '#update_mapping' do
  include_examples 'transport#update_mapping'
end
