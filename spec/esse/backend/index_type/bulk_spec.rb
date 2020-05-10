# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_contexts/geos_index_definition'

RSpec.describe Esse::Backend::Index do
  include_context 'geos index definition'

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
end