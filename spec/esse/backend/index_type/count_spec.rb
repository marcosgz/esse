# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_contexts/geos_index_definition'

RSpec.describe Esse::Backend::Index do
  include_context 'geos index definition'

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
end