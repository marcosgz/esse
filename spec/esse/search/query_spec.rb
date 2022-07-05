# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Search::Query do
  describe '#index' do
    before { stub_index(:events) }

    it { expect(described_class.new(EventsIndex, '*').index).to eq(EventsIndex) }
  end

  describe '#options' do
    before { stub_index(:events) }

    it 'forwards elasticsearch request parameters' do
      expect(
        Esse::Search::Query.new(
          EventsIndex,
          '*',
          timeout: '1m'
        ).options
      ).to include(timeout: '1m')
    end
  end

  describe '#definition' do
    before { stub_index(:events) }

    it 'adds the :body to the definition' do
      expect(described_class.new(EventsIndex, { query: {} }).definition).to include(body: { query: {} })
    end

    it 'adds the :q to the definition' do
      expect(described_class.new(EventsIndex, 'foo').definition).to include(q: 'foo')
    end

    it 'converts the :body string to a Hash' do
      expect(described_class.new(EventsIndex, '{"query": {}}').definition).to include(body: { 'query' => {}})
    end
  end

  describe '#response' do
    let(:searcher) { instance_double(Esse::Backend::Index) }
    let(:request_body) { { query: { match_all: {} } } }
    let(:query) { described_class.new(EventsIndex, request_body) }

    before { stub_index(:events) }

    it 'returns a Response' do
      body = elasticsearch_response_fixture(file: 'search_result_empty', version: '7.x', assigns: { index_name: 'geos' })

      expect(searcher).to receive(:search).with(body: request_body).and_return(body)
      expect(EventsIndex).to receive(:elasticsearch).and_return(searcher)

      expect(resp = query.response).to be_an_instance_of(Esse::Search::Response)
      expect(resp.query).to eq(query)
    end
  end

  describe '#raw_limit_value' do
    subject { described_class.new(Class.new(Esse::Index), definition, **params).send(:raw_limit_value) }

    let(:params) { {} }
    let(:definition) { 'term' }

    it { is_expected.to eq(nil) }

    context 'when definition have [:body][:size] value' do
      let(:definition) do
        {
          size: 10
        }
      end

      it { is_expected.to eq(10) }
    end

    context 'when definition have [:body]["size"] value' do
      let(:definition) do
        {
          'size' => 10
        }
      end

      it { is_expected.to eq(10) }
    end

    context 'when params have the :size' do
      let(:params) { { size: 20 } }

      it { is_expected.to eq(20) }
    end
  end

  describe '#raw_offset_value' do
    subject { described_class.new(Class.new(Esse::Index), definition, **params).send(:raw_offset_value) }

    let(:params) { {} }
    let(:definition) { 'term' }

    it { is_expected.to eq(nil) }

    context 'when definition have [:body][:from] value' do
      let(:definition) do
        {
          from: 10
        }
      end

      it { is_expected.to eq(10) }
    end

    context 'when definition have [:body]["from"] value' do
      let(:definition) do
        {
          'from' => 10
        }
      end

      it { is_expected.to eq(10) }
    end

    context 'when params have the :from' do
      let(:params) { { from: 20 } }

      it { is_expected.to eq(20) }
    end
  end
end
