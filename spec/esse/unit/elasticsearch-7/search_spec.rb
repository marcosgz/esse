# frozen_string_literal: true

require 'spec_helper'
stack_describe 'elasticsearch', '7.x', 'elasticsearch#search', es_webmock: true do
  before do
    reset_config!
    stub_index(:geos) do
      repository :country
    end
  end

  describe '.search', events: %w[elasticsearch.search] do
    specify do
      body = elasticsearch_response_fixture(file: 'search_result_empty', version: '7.x', assigns: { index_name: 'geos' })
      stub_es_request(:post, '/geos/_search', res: { status: 200, body: body })

      body = { query: { match_all: {} } }
      resp = GeosIndex.elasticsearch.search(body: body)
      expect(resp).to be_an_instance_of(Hash)
      assert_event 'elasticsearch.search', { request: { index: 'geos', body: body } }
    end
  end
end
