# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Search::Response do
  before { stub_index(:events) }

  subject(:model) { described_class.new(query, raw_response) }

  let(:request_body) { { query: { match_all: {} } } }
  let(:query) { Esse::Search::Query.new(EventsIndex, request_body) }
  let(:raw_response) do
    json = elasticsearch_response_fixture(file: 'search_result_empty', version: '7.x', assigns: { index_name: 'geos' })
    MultiJson.load(json)
  end

  describe '#hits' do
    context 'without data' do
      it 'returns the hits' do
        expect(model.hits).to eq([])
      end
    end

    context 'with data' do
      let(:raw_response) do
        json = elasticsearch_response_fixture(file: 'search_result_with_data', version: '7.x', assigns: { index_name: 'geos' })
        MultiJson.load(json)
      end

      it 'returns the hits' do
        expect(model.hits).not_to be_empty
        expect(model.hits).to eq(raw_response['hits']['hits'])
      end
    end
  end

  describe '#size' do
    context 'without data' do
      it 'returns the size' do
        expect(model.size).to eq(0)
      end
    end

    context 'with data' do
      let(:raw_response) do
        json = elasticsearch_response_fixture(file: 'search_result_with_data', version: '7.x', assigns: { index_name: 'geos' })
        MultiJson.load(json)
      end

      it 'returns the size' do
        expect(model.size).to eq(2)
      end
    end
  end

  describe '#each' do
    context 'without data' do
      it 'returns the hits' do
        expect(model.each).to be_an_instance_of(Enumerator)
      end
    end

    context 'with data' do
      let(:raw_response) do
        json = elasticsearch_response_fixture(file: 'search_result_with_data', version: '7.x', assigns: { index_name: 'geos' })
        MultiJson.load(json)
      end

      it 'returns the hits' do
        expect(model.each.map(&:to_h)).to eq(raw_response['hits']['hits'])
      end
    end
  end
end
