# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/repository_documents_update_documents_attribute'

stack_describe 'elasticsearch', '7.x', Esse::Repository, '.update_documents_attribute' do
  include_examples 'repository.update_documents_attribute'
end
