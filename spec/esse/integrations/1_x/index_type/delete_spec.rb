# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_contexts/geos_index_definition'

RSpec.describe "[ES #{ENV.fetch('STACK_VERSION', '1.x')}] delete document", es_version: '1.x' do
  include_context 'geos index definition'

  describe '.delete!' do
    let(:data) { { name: 'Illinois', pk: 1 } }
    specify do
      es_client do
        expect { GeosIndex::State.elasticsearch.delete!(id: 1) }.to raise_error(
          Elasticsearch::Transport::Transport::Errors::NotFound,
        )
        expect { GeosIndex::State.elasticsearch.delete!(id: 1, suffix: 'v2') }.to raise_error(
          Elasticsearch::Transport::Transport::Errors::NotFound,
        )
        expect(GeosIndex::State.elasticsearch.exist?(id: 1)).to eq(false)
        expect(GeosIndex::State.elasticsearch.exist?(id: 1, suffix: 'v2')).to eq(false)
      end
    end

    specify do
      es_client do
        expect(GeosIndex::State.elasticsearch.index(id: data[:pk], body: data)['created']).to eq(true)
        expect(GeosIndex::State.elasticsearch.delete!(id: data[:pk])['found']).to eq(true)
        expect(GeosIndex::State.elasticsearch.exist?(id: data[:pk])).to eq(false)

        expect(GeosIndex::State.elasticsearch.index(id: data[:pk], suffix: 'v2', body: data)['created']).to eq(true)
        expect(GeosIndex::State.elasticsearch.delete!(id: data[:pk], suffix: 'v2')['found']).to eq(true)
        expect(GeosIndex::State.elasticsearch.exist?(id: data[:pk], suffix: 'v2')).to eq(false)
      end
    end
  end

  describe '.delete' do
    let(:data) { { name: 'Illinois', pk: 1 } }
    specify do
      es_client do
        expect(GeosIndex::State.elasticsearch.delete(id: 1)).to eq(false)
        expect(GeosIndex::State.elasticsearch.exist?(id: 1)).to eq(false)

        expect(GeosIndex::State.elasticsearch.delete(id: 1, suffix: 'v2')).to eq(false)
        expect(GeosIndex::State.elasticsearch.exist?(id: 1, suffix: 'v2')).to eq(false)
      end
    end

    specify do
      es_client do
        expect(GeosIndex::State.elasticsearch.index(id: data[:pk], body: data)['created']).to eq(true)
        expect(GeosIndex::State.elasticsearch.delete(id: data[:pk])['found']).to eq(true)
        expect(GeosIndex::State.elasticsearch.exist?(id: data[:pk])).to eq(false)

        expect(GeosIndex::State.elasticsearch.index(id: data[:pk], body: data, suffix: 'v2')['created']).to eq(true)
        expect(GeosIndex::State.elasticsearch.delete(id: data[:pk], suffix: 'v2')['found']).to eq(true)
        expect(GeosIndex::State.elasticsearch.exist?(id: data[:pk], suffix: 'v2')).to eq(false)
      end
    end
  end
end
