# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/transport_close'

stack_describe 'elasticsearch', '7.x', Esse::Transport, '#close' do
  include_examples 'transport#close'
end