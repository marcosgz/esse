# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_contexts/geos_index_definition'

RSpec.describe Esse::Backend::Index do
  include_context 'geos index definition'

  describe '.update!' do
    let(:data) { { 'name' => 'IL', '_id' => 1 } }

    specify do
      es_client do
        expect { GeosIndex::State.backend.update!(id: data['_id'], body: { doc: {} }) }.to raise_error(
          Elasticsearch::Transport::Transport::Errors::NotFound,
        )
      end
    end

    specify do
      es_client do
        expect(GeosIndex::State.backend.index(id: data['_id'], body: data)['created']).to eq(true)
        expect(GeosIndex::State.backend.update!(id: data['_id'], body: { doc: {} })['_version']).to eq(2)
      end
    end
  end

  describe '.update' do
    let(:data) { { 'name' => 'IL', '_id' => 1 } }

    specify do
      es_client do
        expect(GeosIndex::State.backend.update(id: data['_id'], body: { doc: {} })).to eq(false)
      end
    end

    specify do
      es_client do
        expect(GeosIndex::State.backend.index(id: data['_id'], body: data)['created']).to eq(true)
        expect(GeosIndex::State.backend.update(id: data['_id'], body: { doc: {} })['_version']).to eq(2)
      end
    end
  end
end