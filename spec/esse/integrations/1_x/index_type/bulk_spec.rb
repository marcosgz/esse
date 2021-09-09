# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_contexts/geos_index_definition'

RSpec.describe "[ES #{ENV.fetch("STACK_VERSION", "1.x")}] bulk data", es_version: '1.x' do
  include_context 'geos index definition'

  describe '.bulk' do
    let(:il) { { 'name' => 'IL', '_id' => 1 } }
    let(:md) { { 'name' => 'MD', '_id' => 2 } }
    let(:ny) { { 'name' => 'NY', '_id' => 3 } }

    specify do
      es_client do
        expect(GeosIndex::State.elasticsearch.exist?(id: 1)).to eq(false)
        expect(GeosIndex::State.elasticsearch.exist?(id: 2)).to eq(false)
        expect(GeosIndex::State.elasticsearch.bulk(index: [il, md])['errors']).to eq(false)
        expect(GeosIndex::State.elasticsearch.exist?(id: 1)).to eq(true)
        expect(GeosIndex::State.elasticsearch.exist?(id: 2)).to eq(true)

        operations = {
          create: [ny],
          delete: [md],
          refresh: true,
        }
        expect(GeosIndex::State.elasticsearch.bulk(**operations)['errors']).to eq(false)
        expect(GeosIndex::State.elasticsearch.exist?(id: md['_id'])).to eq(false)
        expect(GeosIndex::State.elasticsearch.find(id: 3)['_source']).to eq('name' => 'NY')
        expect(GeosIndex::State.elasticsearch.bulk(suffix: 'v2', **operations)['errors']).to eq(false)
      end
    end
  end
end
