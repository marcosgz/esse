# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/transport_health'

stack_describe 'elasticsearch', '1.x', Esse::Transport, '#health' do
  include_examples 'transport#health'
end
