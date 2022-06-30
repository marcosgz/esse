# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_contexts/geos_index_definition'

stack_describe '1.x', 'elasticsearch find documents' do
  include_context 'geos index definition'

  describe '.find!' do
    let(:data) { { 'name' => 'Illinois', 'pk' => 1 } }

    specify do
      es_client do
        expect { GeosIndex::State.elasticsearch.find!(id: data['pk']) }.to raise_error(
          Esse::Backend::NotFoundError,
        )
        expect { GeosIndex::State.elasticsearch.find!(id: data['pk'], suffix: 'v2') }.to raise_error(
          Esse::Backend::NotFoundError,
        )
      end
    end

    specify do
      es_client do
        expect(GeosIndex::State.elasticsearch.index(id: data['pk'], body: data)['created']).to eq(true)
        response = GeosIndex::State.elasticsearch.find!(id: data['pk'])
        expect(response['_id']).to eq('1')
        expect(response['_source']).to eq(data)
        expect(response['_type']).to eq('state')
        expect { GeosIndex::County.elasticsearch.find!(id: data['pk']) }.to raise_error(
          Esse::Backend::NotFoundError,
        )
      end
    end
  end

  describe '.find' do
    let(:data) { { 'name' => 'Illinois', 'pk' => 1 } }

    specify do
      es_client do
        expect(GeosIndex::State.elasticsearch.find(id: data['pk'])).to eq(nil)
        expect(GeosIndex::State.elasticsearch.find(id: data['pk'], suffix: 'v2')).to eq(nil)
      end
    end

    specify do
      es_client do
        expect(GeosIndex::State.elasticsearch.index(id: data['pk'], body: data)['created']).to eq(true)
        response = GeosIndex::State.elasticsearch.find(id: data['pk'])
        expect(response['_id']).to eq('1')
        expect(response['_source']).to eq(data)
        expect(response['_type']).to eq('state')
        expect(GeosIndex::County.elasticsearch.find(id: data['pk'])).to eq(nil)
      end
    end

    specify do
      es_client do
        expect(GeosIndex::State.elasticsearch.index(id: data['pk'], body: data, suffix: 'v2')['created']).to eq(true)
        response = GeosIndex::State.elasticsearch.find(id: data['pk'], suffix: 'v2')
        expect(response['_id']).to eq('1')
        expect(response['_source']).to eq(data)
        expect(response['_type']).to eq('state')
      end
    end
  end
end
