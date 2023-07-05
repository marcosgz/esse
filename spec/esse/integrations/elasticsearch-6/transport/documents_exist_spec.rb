# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/transport_documents_exist'

stack_describe 'elasticsearch', '6.x', Esse::Transport, '#exist?' do
  include_examples 'transport#exist?', doc_type: true
end
