# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/cluster_api_aliases'

stack_describe 'elasticsearch', '8.x', Esse::ClientProxy, '#aliases' do
  include_examples 'cluster_api#aliases'
end