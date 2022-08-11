# frozen_string_literal: true

require 'spec_helper'
stack_describe 'elasticsearch', '7.x', 'elasticsearch#scroll', es_webmock: true do
  before do
    reset_config!
    stub_index(:geos) do
      repository :country
    end
  end

  describe '.scroll', events: %w[elasticsearch.search] do
    let(:request_body) do
      { scroll_id: '123' }
    end

    specify do
      response_body = elasticsearch_response_fixture(file: 'search_scroll_result_with_data', version: '7.x', assigns: { total: 4, index_name: 'geos' })
      stub_es_request(:post, '/_search/scroll', params: {scroll: '1m'}, res: { status: 200, body: response_body })

      resp = GeosIndex.cluster.api.scroll(scroll: '1m', body: request_body)
      expect(resp).to be_an_instance_of(Hash)
      assert_event 'elasticsearch.search', { request: { scroll: '1m', body: request_body } }
    end

    it 'raises an exception if the api throws an error' do
      response_body = elasticsearch_response_fixture(file: 'search_scroll_result_expired', version: '7.x')
      stub_es_request(:post, '/_search/scroll', params: {scroll: '1m'}, res: { status: 404, body: response_body })

      expect {
        GeosIndex.cluster.api.scroll(scroll: '1m', body: request_body)
      }.to raise_error(Esse::Backend::NotFoundError)
      refute_event 'elasticsearch.search'
    end
  end
end
