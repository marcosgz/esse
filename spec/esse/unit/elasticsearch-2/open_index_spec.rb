# frozen_string_literal: true

require 'spec_helper'

stack_describe 'elasticsearch', '2.x', 'elasticsearch#open', es_webmock: true do
  before do
    reset_config!
    stub_index(:geos) do
      define_type :city
      define_type :county
    end
  end

  describe '.open!', events: %w[elasticsearch.open] do
    it 'raises an exception if the elasticsearch-api throws an error' do
      body = elasticsearch_response_fixture(file: 'index_not_found', version: '2.x', assigns: { index_name: 'geos' })
      stub_es_request(:post, '/geos/_open', res: { status: 404, body: body })
      expect {
        GeosIndex.elasticsearch.open!
      }.to raise_error(Esse::Backend::NotFoundError)
      refute_event 'elasticsearch.open'
    end

    it 'opens the index' do
      stub_es_request(:post, '/geos/_open', res: { status: 200, body: { acknowledged: true } })

      GeosIndex.elasticsearch.open!
      assert_event 'elasticsearch.open', { request: { index: 'geos' } }
    end

    it 'allows specify custom index name when passing the :prefix option' do
      stub_es_request(:post, '/geos_v1/_open', res: { status: 200, body: { acknowledged: true } })

      GeosIndex.elasticsearch.open!(suffix: 'v1')
      assert_event 'elasticsearch.open', { request: { index: 'geos_v1' } }
    end

    it 'forwards elasticsearch-api related attributes to the client request' do
      stub_es_request(:post, '/geos/_open', params: { timeout: '10s' }, res: { status: 200, body: { acknowledged: true }})

      GeosIndex.elasticsearch.open!(timeout: '10s')
      assert_event 'elasticsearch.open', { request: { index: 'geos' } }
    end
  end

  describe '.open', events: %w[elasticsearch.open] do
    it 'does NOT raises an exception if the elasticsearch-api throws an error' do
      body = elasticsearch_response_fixture(file: 'index_not_found', version: '2.x', assigns: { index_name: 'geos' })
      stub_es_request(:post, '/geos/_open', res: { status: 404, body: body })
      expect(GeosIndex.elasticsearch.open).to eq('errors' => true)
      refute_event 'elasticsearch.open'
    end

    it 'opens the index' do
      stub_es_request(:post, '/geos/_open', res: { status: 200, body: { acknowledged: true } })

      GeosIndex.elasticsearch.open
      assert_event 'elasticsearch.open', { request: { index: 'geos' } }
    end

    it 'allows specify custom index name when passing the :prefix option' do
      stub_es_request(:post, '/geos_v1/_open', res: { status: 200, body: { acknowledged: true } })

      GeosIndex.elasticsearch.open(suffix: 'v1')
      assert_event 'elasticsearch.open', { request: { index: 'geos_v1' } }
    end

    it 'forwards elasticsearch-api related attributes to the client request' do
      stub_es_request(:post, '/geos/_open', params: { timeout: '10s' }, res: { status: 200, body: { acknowledged: true }})

      GeosIndex.elasticsearch.open(timeout: '10s')
      assert_event 'elasticsearch.open', { request: { index: 'geos' } }
    end
  end
end
