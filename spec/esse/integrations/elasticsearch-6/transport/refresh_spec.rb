# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/transport_refresh'

stack_describe 'elasticsearch', '6.x', Esse::Transport, '#refresh' do
  include_examples 'transport#refresh'
end
