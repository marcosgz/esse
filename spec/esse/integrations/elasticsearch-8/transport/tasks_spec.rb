# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/transport_tasks'

stack_describe 'elasticsearch', '8.x', Esse::Transport, '#tasks' do
  include_examples 'transport#tasks'
  include_examples 'transport#task'
  include_examples 'transport#cancel_task'
end
