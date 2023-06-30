# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/transport_delete_index'

stack_describe 'elasticsearch', '2.x', Esse::Transport, '#delete_index' do
  include_examples 'transport#delete_index'
end
