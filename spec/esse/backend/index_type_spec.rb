# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Backend::Index do
  before do
    stub_index(:geos) do
      define_type :state do
        mappings('name' => { 'type' => 'string' }, 'pk' => { 'type' => 'long'})
      end
      define_type :county do
        mappings('name' => { 'type' => 'string' }, 'pk' => { 'type' => 'long'})
      end
    end
  end

  describe '.create' do
    specify do
      es_client do
        response = GeosIndex::State.backend.create(id: 1, body: { name: 'Illinois', pk: 1 })
        expect(response['created']).to eq(true)
        expect(response['_version']).to eq(1)
        expect(response['_id']).to eq('1')
        expect(response['_type']).to eq('state')

        response = GeosIndex::State.backend.create(id: 1, body: { name: 'IL', pk: 1 })
        expect(response['created']).to eq(false)
        expect(response['_version']).to eq(2)
        expect(response['_id']).to eq('1')
      end
    end
  end

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
        expect(GeosIndex::State.backend.create(id: data[:pk], body: data)['created']).to eq(true)
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
        expect(GeosIndex::State.backend.create(id: data[:pk], body: data)['created']).to eq(true)
        expect(GeosIndex::State.backend.delete(id: data[:pk])['found']).to eq(true)
        expect(GeosIndex::State.backend.exist?(id: data[:pk])).to eq(false)
      end
    end
  end

  describe '.exist?' do
    let(:data) { { name: 'Illinois', pk: 1 } }

    specify do
      es_client do
        expect(GeosIndex::State.backend.exist?(id: data[:pk])).to eq(false)
      end
    end

    specify do
      es_client do
        expect(GeosIndex::State.backend.create(id: data[:pk], body: data)['created']).to eq(true)
        expect(GeosIndex::State.backend.exist?(id: data[:pk])).to eq(true)
      end
    end
  end

  describe '.find!' do
    let(:data) { { 'name' => 'Illinois', 'pk' => 1 } }

    specify do
      es_client do
        expect { GeosIndex::State.backend.find!(id: data['pk']) }.to raise_error(
          Elasticsearch::Transport::Transport::Errors::NotFound,
        )
      end
    end

    specify do
      es_client do
        expect(GeosIndex::State.backend.create(id: data['pk'], body: data)['created']).to eq(true)
        response = GeosIndex::State.backend.find!(id: data['pk'])
        expect(response['_id']).to eq('1')
        expect(response['_source']).to eq(data)
        expect(response['_type']).to eq('state')
        expect { GeosIndex::County.backend.find!(id: data['pk']) }.to raise_error(
          Elasticsearch::Transport::Transport::Errors::NotFound,
        )
      end
    end
  end

  describe '.find' do
    let(:data) { { 'name' => 'Illinois', 'pk' => 1 } }

    specify do
      es_client do
        expect(GeosIndex::State.backend.find(id: data['pk'])).to eq(nil)
      end
    end

    specify do
      es_client do
        expect(GeosIndex::State.backend.create(id: data['pk'], body: data)['created']).to eq(true)
        response = GeosIndex::State.backend.find(id: data['pk'])
        expect(response['_id']).to eq('1')
        expect(response['_source']).to eq(data)
        expect(response['_type']).to eq('state')
        expect(GeosIndex::County.backend.find(id: data['pk'])).to eq(nil)
      end
    end
  end

  describe '.count' do
    let(:data) { { 'name' => 'Illinois', 'pk' => 1 } }

    specify do
      es_client do
        expect(GeosIndex::State.backend.count).to eq(0)
      end
    end

    specify do
      es_client do
        expect(GeosIndex::State.backend.create(id: data['pk'], body: data, refresh: true)['created']).to eq(true)
        expect(GeosIndex::State.backend.count).to eq(1)
        expect(GeosIndex::County.backend.count).to eq(0)
      end
    end
  end
end
