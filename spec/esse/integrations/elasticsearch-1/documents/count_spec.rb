# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_contexts/geos_index_definition'

stack_describe '1.x', 'elasticsearch count' do
  include_context 'geos index definition'

  describe '.count' do
    let(:data) { { 'name' => 'Illinois', 'pk' => 1 } }

    specify do
      es_client do
        expect(GeosIndex::State.elasticsearch.count).to eq(0)
        expect(GeosIndex::State.elasticsearch.count(suffix: 'v2')).to eq(0)
      end
    end

    specify do
      es_client do
        expect(GeosIndex::State.elasticsearch.index(id: data['pk'], body: data, refresh: true)['created']).to eq(true)
        expect(GeosIndex::State.elasticsearch.count).to eq(1)
        expect(GeosIndex::County.elasticsearch.count).to eq(0)

        expect(GeosIndex::State.elasticsearch.index(id: data['pk'], body: data, refresh: true, suffix: 'v2')['created']).to eq(true)
        expect(GeosIndex::State.elasticsearch.count(suffix: 'v2')).to eq(1)
      end
    end
  end
end
