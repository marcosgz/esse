# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/transport_open'

stack_describe 'elasticsearch', '1.x', Esse::Transport, '#open' do
  include_examples 'transport#open'
end
