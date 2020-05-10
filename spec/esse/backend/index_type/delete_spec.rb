# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_contexts/geos_index_definition'

RSpec.describe Esse::Backend::Index do
  include_context 'geos index definition'

  describe '.delete!' do
    let(:data) { { name: 'Illinois', pk: 1 } }
    specify do
      es_client do
        expect { GeosIndex::State.backend.delete!(id: 1) }.to raise_error(
          Elasticsearch::Transport::Transport::Errors::NotFound,
        )
        expect(GeosIndex::State.backend.exist?(id: 1)).to eq(false)
      end
    end

    specify do
      es_client do
        expect(GeosIndex::State.backend.index(id: data[:pk], body: data)['created']).to eq(true)
        expect(GeosIndex::State.backend.delete!(id: data[:pk])['found']).to eq(true)
        expect(GeosIndex::State.backend.exist?(id: data[:pk])).to eq(false)
      end
    end
  end

  describe '.delete' do
    let(:data) { { name: 'Illinois', pk: 1 } }
    specify do
      es_client do
        expect(GeosIndex::State.backend.delete(id: 1)).to eq(false)
        expect(GeosIndex::State.backend.exist?(id: 1)).to eq(false)
      end
    end

    specify do
      es_client do
        expect(GeosIndex::State.backend.index(id: data[:pk], body: data)['created']).to eq(true)
        expect(GeosIndex::State.backend.delete(id: data[:pk])['found']).to eq(true)
        expect(GeosIndex::State.backend.exist?(id: data[:pk])).to eq(false)
      end
    end
  end
end