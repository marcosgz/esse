# frozen_string_literal: true

require 'spec_helper'
stack_describe 'elasticsearch', '7.x', 'elasticsearch#close', es_webmock: true do
  before do
    reset_config!
    stub_index(:geos) do
      repository :city
      repository :county
    end
  end

  describe '.close', events: %w[elasticsearch.close] do
    it 'raises an exception if the elasticsearch-api throws an error' do
      body = elasticsearch_response_fixture(file: 'index_not_found', version: '7.x', assigns: { index_name: 'geos' })
      stub_es_request(:post, '/geos/_close', res: { status: 404, body: body })
      expect {
        GeosIndex.close
      }.to raise_error(Esse::Transport::NotFoundError)
      refute_event 'elasticsearch.close'
    end

    it 'closes the index' do
      stub_es_request(:post, '/geos/_close', res: { status: 200, body: { acknowledged: true } })

      GeosIndex.close
      assert_event 'elasticsearch.close', { request: { index: 'geos' } }
    end

    it 'allows specify custom index name when passing the :prefix option' do
      stub_es_request(:post, '/geos_v1/_close', res: { status: 200, body: { acknowledged: true } })

      GeosIndex.close(suffix: 'v1')
      assert_event 'elasticsearch.close', { request: { index: 'geos_v1' } }
    end

    it 'forwards elasticsearch-api related attributes to the client request' do
      stub_es_request(:post, '/geos/_close', params: { timeout: '10s' }, res: { status: 200, body: { acknowledged: true }})

      GeosIndex.close(timeout: '10s')
      assert_event 'elasticsearch.close', { request: { index: 'geos' } }
    end
  end
end
