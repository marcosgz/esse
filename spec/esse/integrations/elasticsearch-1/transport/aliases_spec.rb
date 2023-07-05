# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/transport_aliases'

stack_describe 'elasticsearch', '1.x', Esse::Transport, '#aliases' do
  include_examples 'transport#aliases'
end
