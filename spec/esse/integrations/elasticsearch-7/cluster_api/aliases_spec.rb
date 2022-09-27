# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/cluster_api_aliases'

stack_describe 'elasticsearch', '7.x', Esse::ClientProxy, '#aliases' do
  include_context 'with geos index definition'
  include_examples 'cluster_api#aliases'
end
