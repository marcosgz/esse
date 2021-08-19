# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_contexts/geos_index_definition'

RSpec.describe "[ES #{ENV.fetch('STACK_VERSION', '1.x')}] import documents", es_version: '1.x' do
  include_context 'geos index definition'

  describe '.import' do
    specify do
      es_client do
        GeosIndex.elasticsearch.create_index
        expect { GeosIndex::State.elasticsearch.import(context: {}, refresh: true) }.not_to raise_error
        expect(GeosIndex::State.elasticsearch.count).to eq(3)
        expect(GeosIndex::County.elasticsearch.count).to eq(0)
      end
    end

    specify do
      es_client do
        GeosIndex.elasticsearch.create_index
        expect { GeosIndex::State.elasticsearch.import(context: {}, suffix: 'v2', refresh: true) }.not_to raise_error
        expect(GeosIndex::State.elasticsearch.count).to eq(0)
        expect(GeosIndex::County.elasticsearch.count).to eq(0)
        expect(GeosIndex::State.elasticsearch.count(suffix: 'v2')).to eq(3)
        expect(GeosIndex::County.elasticsearch.count(suffix: 'v2')).to eq(0)
      end
    end

    specify do
      es_client do
        GeosIndex.elasticsearch.create_index
        context = {
          conditions: ->(entry) { entry.id < 3 },
        }
        expect { GeosIndex::State.elasticsearch.import(context: context, refresh: true) }.not_to raise_error
        expect(GeosIndex::State.elasticsearch.count).to eq(2)
        expect(GeosIndex::County.elasticsearch.count).to eq(0)
      end
    end
  end
end
