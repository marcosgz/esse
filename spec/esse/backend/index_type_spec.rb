# frozen_string_literal: true

require 'spec_helper'

class DummyGeosSerializer
  def initialize(entry, _scope)
    @entry = entry
  end

  def as_json
    {
      _id: @entry.uuid,
      pk: @entry.id,
      name: @entry.name,
    }
  end
end

RSpec.describe Esse::Backend::Index do
  before do
    stub_index(:geos) do
      define_type :state do
        mappings('name' => { 'type' => 'string' }, 'pk' => { 'type' => 'long'})
        collection do |context, &block|
          [
            [
              OpenStruct.new(id: 1, uuid: '11-11', name: 'Il'),
              OpenStruct.new(id: 2, uuid: '22-22', name: 'Md')
            ],
            [
              OpenStruct.new(id: 3, uuid: '33-33', name: 'Ny')
            ]
          ].each do |batch|
            states = context[:conditions] ? batch.select(&context[:conditions]) : batch
            block.call(states, context) unless states.empty?
          end
        end
        serializer DummyGeosSerializer
      end
      define_type :county do
        mappings('name' => { 'type' => 'string' }, 'pk' => { 'type' => 'long'})
        collection do |context, &block|
          [
            [
              OpenStruct.new(id: 999, uuid: '99-99', name: 'Cook County', state: 'il'),
              OpenStruct.new(id: 888, uuid: '88-88', name: 'Baltimore County', state: 'md')
            ],
            [
              OpenStruct.new(id: 777, uuid: '77-77', name: 'Bronx County', state: 'ny')
            ]
          ].each do |batch|
            counties = context[:conditions] ? batch.select(&context[:conditions]) : batch
            block.call(counties, context) unless counties.empty?
          end
        end
        serializer DummyGeosSerializer
      end
    end
  end

  describe '.index' do
    specify do
      es_client do
        response = GeosIndex::State.backend.index(id: 1, body: { name: 'Illinois', pk: 1 })
        expect(response['created']).to eq(true)
        expect(response['_version']).to eq(1)
        expect(response['_id']).to eq('1')
        expect(response['_type']).to eq('state')

        response = GeosIndex::State.backend.index(id: 1, body: { name: 'IL', pk: 1 })
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

  describe '.exist?' do
    let(:data) { { name: 'Illinois', pk: 1 } }

    specify do
      es_client do
        expect(GeosIndex::State.backend.exist?(id: data[:pk])).to eq(false)
      end
    end

    specify do
      es_client do
        expect(GeosIndex::State.backend.index(id: data[:pk], body: data)['created']).to eq(true)
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
        expect(GeosIndex::State.backend.index(id: data['pk'], body: data)['created']).to eq(true)
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

  describe '.find' do
    let(:data) { { 'name' => 'Illinois', 'pk' => 1 } }

    specify do
      es_client do
        expect(GeosIndex::State.backend.find(id: data['pk'])).to eq(nil)
      end
    end

    specify do
      es_client do
        expect(GeosIndex::State.backend.index(id: data['pk'], body: data)['created']).to eq(true)
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
        expect(GeosIndex::State.backend.index(id: data['pk'], body: data, refresh: true)['created']).to eq(true)
        expect(GeosIndex::State.backend.count).to eq(1)
        expect(GeosIndex::County.backend.count).to eq(0)
      end
    end
  end

  describe '.bulk' do
    let(:il) { { 'name' => 'IL', '_id' => 1 } }
    let(:md) { { 'name' => 'MD', '_id' => 2 } }
    let(:ny) { { 'name' => 'NY', '_id' => 3 } }

    specify do
      es_client do
        expect(GeosIndex::State.backend.exist?(id: 1)).to eq(false)
        expect(GeosIndex::State.backend.exist?(id: 2)).to eq(false)
        expect(GeosIndex::State.backend.bulk(index: [il, md])['errors']).to eq(false)
        expect(GeosIndex::State.backend.exist?(id: 1)).to eq(true)
        expect(GeosIndex::State.backend.exist?(id: 2)).to eq(true)

        operations = {
          create: [ny],
          delete: [md],
          refresh: true,
        }
        expect(GeosIndex::State.backend.bulk(**operations)['errors']).to eq(false)
        expect(GeosIndex::State.backend.exist?(id: md['_id'])).to eq(false)
        expect(GeosIndex::State.backend.find(id: 3)['_source']).to eq('name' => 'NY')
      end
    end
  end

  describe '.import' do
    specify do
      es_client do
        GeosIndex.backend.create
        expect { GeosIndex::State.backend.import(context: {}, refresh: true) }.not_to raise_error
        expect(GeosIndex::State.backend.count).to eq(3)
        expect(GeosIndex::County.backend.count).to eq(0)
      end
    end

    specify do
      es_client do
        GeosIndex.backend.create
        context = {
          conditions: ->(entry) { entry.id < 3 },
        }
        expect { GeosIndex::State.backend.import(context: context, refresh: true) }.not_to raise_error
        expect(GeosIndex::State.backend.count).to eq(2)
        expect(GeosIndex::County.backend.count).to eq(0)
      end
    end
  end
end
