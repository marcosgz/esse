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
    let(:request_body) do
      { query: { match_all: {} } }
    end

    specify do
      response_body = elasticsearch_response_fixture(file: 'search_result_empty', version: '7.x', assigns: { index_name: 'geos' })
      stub_es_request(:post, '/geos/_search', res: { status: 200, body: response_body })

      resp = GeosIndex.cluster.api.search(index: 'geos', body: request_body)
      expect(resp).to be_an_instance_of(Hash)
      assert_event 'elasticsearch.search', { request: { index: 'geos', body: request_body } }
    end

    it 'does not raise Esse::Transport::ReadonlyClusterError error when the cluster is readonly' do
      response_body = elasticsearch_response_fixture(file: 'search_result_empty', version: '7.x', assigns: { index_name: 'geos' })
      stub_es_request(:post, '/geos/_search', res: { status: 200, body: response_body })

      GeosIndex.cluster.readonly = true
      expect {
        GeosIndex.cluster.api.search(index: 'geos', body: request_body)
      }.not_to raise_error
    end

    it 'raises an exception if the api throws an error' do
      response_body = elasticsearch_response_fixture(file: 'search_result_bad_request', version: '7.x')
      stub_es_request(:post, '/geos/_search', res: { status: 400, body: response_body })

      expect {
        GeosIndex.cluster.api.search(index: 'geos', body: request_body)
      }.to raise_error(Esse::Transport::BadRequestError)
      refute_event 'elasticsearch.search'
    end
  end
end
