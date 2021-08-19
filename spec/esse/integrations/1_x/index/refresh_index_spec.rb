# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "[ES #{ENV.fetch('STACK_VERSION', '1.x')}] refresh index", es_version: '1.x' do
  before do
    stub_index(:dummies)
  end

  describe '.refresh!' do
    specify do
      es_client do
        expect { DummiesIndex.elasticsearch.refresh! }.to raise_error(
          Elasticsearch::Transport::Transport::Errors::NotFound,
        )
      end
    end

    specify do
      es_client do
        DummiesIndex.elasticsearch.create_index!
        expect(DummiesIndex.elasticsearch.refresh!['_shards']).to be_a_kind_of(Hash)
      end
    end
  end

  describe '.refresh' do
    context 'when index does not exists' do
      specify do
        es_client { expect(DummiesIndex.elasticsearch.refresh).to eq('errors' => true) }
      end
    end

    context 'when index exists' do
      specify do
        es_client do
          DummiesIndex.elasticsearch.create_index!
          expect(DummiesIndex.elasticsearch.refresh).to be_a_kind_of(Hash)
        end
      end
    end
  end
end
