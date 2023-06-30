# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/index_documents_exist'

stack_describe 'elasticsearch', '1.x', Esse::Index, '.exist?' do
  include_examples 'index.exist?'
end
