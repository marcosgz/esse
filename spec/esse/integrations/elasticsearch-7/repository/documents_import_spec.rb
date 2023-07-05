# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/repository_documents_import'

stack_describe 'elasticsearch', '7.x', Esse::Repository, '.import' do
  include_examples 'repository.import'
end
