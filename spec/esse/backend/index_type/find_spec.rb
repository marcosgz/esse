# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_contexts/geos_index_definition'

RSpec.describe Esse::Backend::Index do
  include_context 'geos index definition'

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
end
