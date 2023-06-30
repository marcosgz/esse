# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/transport_refresh'

stack_describe 'elasticsearch', '5.x', Esse::Transport, '#refresh' do
  include_examples 'transport#refresh'
end
