# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_contexts/geos_index_definition'

RSpec.describe Esse::Backend::Index do
  include_context 'geos index definition'

  describe '.import' do
    specify do
      es_client do
        GeosIndex.backend.create_index
        expect { GeosIndex::State.backend.import(context: {}, refresh: true) }.not_to raise_error
        expect(GeosIndex::State.backend.count).to eq(3)
        expect(GeosIndex::County.backend.count).to eq(0)
      end
    end

    specify do
      es_client do
        GeosIndex.backend.create_index
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