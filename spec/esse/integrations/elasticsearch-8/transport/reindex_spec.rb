# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/transport_reindex'

stack_describe 'elasticsearch', '8.x', Esse::Transport, '#reindex' do
  include_examples 'transport#reindex'
end
