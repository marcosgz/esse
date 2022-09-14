# frozen_string_literal: true

require 'spec_helper'
stack_describe 'elasticsearch', '7.x', 'elasticsearch#clear_scroll', es_webmock: true do
  before do
    reset_config!
    stub_index(:geos) do
      repository :country
    end
  end

  describe '.clear_scroll' do
    let(:request_body) do
      { scroll_id: '123' }
    end

    specify do
      response_body = elasticsearch_response_fixture(file: 'clear_scroll_succeeded', version: '7.x', assigns: { total: 4, index_name: 'geos' })
      stub_es_request(:delete, '/_search/scroll', res: { status: 200, body: response_body })

      resp = GeosIndex.cluster.api.clear_scroll(body: request_body)
      expect(resp).to be_an_instance_of(Hash)
    end

    it 'raises an exception if the api throws an error' do
      response_body = elasticsearch_response_fixture(file: 'clear_scroll_not_found', version: '7.x')
      stub_es_request(:delete, '/_search/scroll', res: { status: 404, body: response_body })

      expect {
        GeosIndex.cluster.api.clear_scroll(body: request_body)
      }.to raise_error(Esse::Transport::NotFoundError)
    end
  end
end
