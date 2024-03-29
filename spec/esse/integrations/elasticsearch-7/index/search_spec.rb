# frozen_string_literal: true

require 'spec_helper'
stack_describe 'elasticsearch', '7.x', 'elasticsearch#search' do
  before do
    reset_config!
    stub_index(:geos) do
      repository :country do
      end
    end
  end

  describe '.search', events: %w[elasticsearch.search] do
    it 'returns a Response' do
      es_client do |client, _conf, cluster|
        GeosIndex.create_index(alias: true)

        expect(resp = GeosIndex.search(query: { match_all: {} }).response).to be_an_instance_of(Esse::Search::Response)
        expect(resp.raw_response).to have_key('hits')
      end
    end
  end
end
