# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/transport_create_index'

stack_describe 'elasticsearch', '1.x', Esse::Transport, '#create_index' do
  include_examples 'transport#create_index'
end
