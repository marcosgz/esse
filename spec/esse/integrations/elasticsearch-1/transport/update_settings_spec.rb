# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/transport_update_settings'

stack_describe 'elasticsearch', '1.x', Esse::Transport, '#update_settings' do
  include_examples 'transport#update_settings'
end
