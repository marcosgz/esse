# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/transport_update_aliases'

stack_describe 'elasticsearch', '6.x', Esse::Transport, '#update_aliases' do
  include_examples 'transport#update_aliases'
end
