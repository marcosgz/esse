# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_contexts/geos_index_definition'

stack_describe 'elasticsearch', '1.x', 'elasticsearch index documents' do
  include_context 'geos index definition'

  describe '.index' do
    specify do
      es_client do
        response = GeosIndex::State.elasticsearch.index(id: 1, body: { name: 'Illinois', pk: 1 })
        expect(response['created']).to eq(true)
        expect(response['_version']).to eq(1)
        expect(response['_id']).to eq('1')
        expect(response['_type']).to eq('state')

        response = GeosIndex::State.elasticsearch.index(id: 1, body: { name: 'IL', pk: 1 })
        expect(response['created']).to eq(false)
        expect(response['_version']).to eq(2)
        expect(response['_id']).to eq('1')

        response = GeosIndex::State.elasticsearch.index(id: 1, suffix: 'v2', body: { name: 'IL', pk: 1 })
        expect(response['created']).to eq(true)
        expect(response['_version']).to eq(1)
        expect(response['_id']).to eq('1')
      end
    end
  end
end
