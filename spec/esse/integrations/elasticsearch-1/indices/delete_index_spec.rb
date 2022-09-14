# frozen_string_literal: true

require 'spec_helper'

stack_describe 'elasticsearch', '1.x', 'elasticsearch delete index' do
  before do
    stub_index(:dummies)
  end

  describe '.delete_index' do
    specify do
      es_client do
        expect(DummiesIndex.elasticsearch.delete_index(suffix: nil)).to eq('errors' => true)
      end
    end

    specify do
      es_client do
        expect(DummiesIndex.elasticsearch.delete_index(suffix: 'v1')).to eq('errors' => true)
      end
    end

    specify do
      es_client do
        expect(DummiesIndex.elasticsearch.create_index(suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.elasticsearch.delete_index(suffix: 'v1')['acknowledged']).to eq(true)
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.elasticsearch.create_index(suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.elasticsearch.create_index(alias: false, suffix: 'v2')['acknowledged']).to eq(true)
        expect(DummiesIndex.elasticsearch.delete_index(suffix: nil)['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies")).to eq(false)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v1")).to eq(false)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v2")).to eq(true)
      end
    end
  end

  describe '.delete_index!' do
    specify do
      es_client do
        expect { DummiesIndex.elasticsearch.delete_index!(suffix: nil) }.to raise_error(
          Esse::Transport::NotFoundError,
        )
      end
    end

    specify do
      es_client do
        expect { DummiesIndex.elasticsearch.delete_index!(suffix: 'v1') }.to raise_error(
          Esse::Transport::NotFoundError,
        )
      end
    end

    specify do
      es_client do
        expect(DummiesIndex.elasticsearch.create_index(suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.elasticsearch.delete_index!(suffix: 'v1')['acknowledged']).to eq(true)
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.elasticsearch.create_index(suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.elasticsearch.create_index(alias: false, suffix: 'v2')['acknowledged']).to eq(true)
        expect(DummiesIndex.elasticsearch.delete_index!(suffix: nil)['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies")).to eq(false)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v1")).to eq(false)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v2")).to eq(true)
      end
    end
  end
end
