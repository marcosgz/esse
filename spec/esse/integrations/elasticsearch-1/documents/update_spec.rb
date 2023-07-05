# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_contexts/geos_index_definition'

stack_describe 'elasticsearch', '1.x', 'elasticsearch update document' do
  include_context 'with geos index definition'

  describe '.update!' do
    let(:data) { { 'name' => 'IL', '_id' => 1 } }

    specify do
      es_client do
        expect { GeosIndex::State.elasticsearch.update!(id: data['_id'], body: { doc: {} }) }.to raise_error(
          Esse::Transport::NotFoundError,
        )
        expect { GeosIndex::State.elasticsearch.update!(id: data['_id'], body: { doc: {} }, suffix: 'v2') }.to raise_error(
          Esse::Transport::NotFoundError,
        )
      end
    end

    specify do
      es_client do
        expect(GeosIndex::State.elasticsearch.index(id: data['_id'], body: data)['created']).to eq(true)
        expect(GeosIndex::State.elasticsearch.update!(id: data['_id'], body: { doc: {} })['_version']).to eq(2)

        expect(GeosIndex::State.elasticsearch.index(id: data['_id'], body: data, suffix: 'v2')['created']).to eq(true)
        expect(GeosIndex::State.elasticsearch.update!(id: data['_id'], body: { doc: {} }, suffix: 'v2')['_version']).to eq(2)
      end
    end
  end

  describe '.update' do
    let(:data) { { 'name' => 'IL', '_id' => 1 } }

    specify do
      es_client do
        expect(GeosIndex::State.elasticsearch.update(id: data['_id'], body: { doc: {} })).to eq('errors' => true)
        expect(GeosIndex::State.elasticsearch.update(id: data['_id'], body: { doc: {} }, suffix: 'v2')).to eq('errors' => true)
      end
    end

    specify do
      es_client do
        expect(GeosIndex::State.elasticsearch.index(id: data['_id'], body: data)['created']).to eq(true)
        expect(GeosIndex::State.elasticsearch.update(id: data['_id'], body: { doc: {} })['_version']).to eq(2)

        expect(GeosIndex::State.elasticsearch.index(id: data['_id'], body: data, suffix: 'v2')['created']).to eq(true)
        expect(GeosIndex::State.elasticsearch.update(id: data['_id'], body: { doc: {} }, suffix: 'v2')['_version']).to eq(2)
      end
    end
  end
end
