# frozen_string_literal: true

require 'spec_helper'

stack_describe '1.x', 'elasticsearch create index' do
  before do
    stub_index(:dummies)
  end

  describe '.create!' do
    specify do
      es_client do
        expect(DummiesIndex.elasticsearch.create_index['acknowledged']).to eq(true)
      end
    end

    it 'creates a suffixed index and its alias' do
      es_client do |client, _conf, cluster|
        allow(Esse).to receive(:timestamp).and_return('2020')
        expect(DummiesIndex.elasticsearch.create_index!['acknowledged']).to eq(true)
        expect(DummiesIndex.elasticsearch.create_index!(suffix: 'v1')['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies")).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v1")).to eq(true)
        expect { DummiesIndex.elasticsearch.create_index!(suffix: 'v1') }.to raise_error(
          Elasticsearch::Transport::Transport::Errors::BadRequest,
        ).with_message(/\[#{cluster.index_prefix}_dummies_v1\] already exists/)
        expect(DummiesIndex.elasticsearch.indices).to match_array(
          [
            "#{cluster.index_prefix}_dummies_2020",
            "#{cluster.index_prefix}_dummies_v1"
          ],
        )
        expect(DummiesIndex.elasticsearch.aliases).to match_array(
          [
            "#{cluster.index_prefix}_dummies"
          ],
        )
      end
    end

    it 'creates a suffixed index without alias' do
      es_client do |client, _conf, cluster|
        allow(Esse).to receive(:timestamp).and_return('2020')
        expect(DummiesIndex.elasticsearch.create_index!(alias: false)['acknowledged']).to eq(true)
        expect(DummiesIndex.elasticsearch.create_index!(alias: false, suffix: 'v1')['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies")).to eq(false)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v1")).to eq(true)
        expect { DummiesIndex.elasticsearch.create_index!(alias: false, suffix: 'v1') }.to raise_error(
          Elasticsearch::Transport::Transport::Errors::BadRequest,
        ).with_message(/\[#{cluster.index_prefix}_dummies_v1\] already exists/)
        expect(DummiesIndex.elasticsearch.indices).to match_array([])
        expect(DummiesIndex.elasticsearch.aliases).to eq([])
      end
    end
  end

  describe '.create' do
    specify do
      es_client do
        expect(DummiesIndex.elasticsearch.create_index['acknowledged']).to eq(true)
      end
    end

    it 'creates a suffixed index and its alias' do
      es_client do |client, _conf, cluster|
        allow(Esse).to receive(:timestamp).and_return('2020')
        expect(DummiesIndex.elasticsearch.create_index['acknowledged']).to eq(true)
        expect(DummiesIndex.elasticsearch.create_index(suffix: 'v1')['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies")).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v1")).to eq(true)
        expect(DummiesIndex.elasticsearch.create_index(suffix: 'v1')).to eq('errors' => true)
        expect(DummiesIndex.elasticsearch.create_index(suffix: 'v2')['acknowledged']).to eq(true)
        expect(DummiesIndex.elasticsearch.indices).to match_array(
          [
            "#{cluster.index_prefix}_dummies_2020",
            "#{cluster.index_prefix}_dummies_v1",
            "#{cluster.index_prefix}_dummies_v2"
          ],
        )
        expect(DummiesIndex.elasticsearch.aliases).to match_array(
          [
            "#{cluster.index_prefix}_dummies"
          ],
        )
      end
    end

    it 'creates a suffixed index without alias' do
      es_client do |client, _conf, cluster|
        allow(Esse).to receive(:timestamp).and_return('2020')
        expect(DummiesIndex.elasticsearch.create_index(alias: false)['acknowledged']).to eq(true)
        expect(DummiesIndex.elasticsearch.create_index(alias: false, suffix: 'v1')['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies")).to eq(false)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v1")).to eq(true)
        expect(DummiesIndex.elasticsearch.create_index(alias: false, suffix: 'v1')).to eq('errors' => true)
        expect(DummiesIndex.elasticsearch.create_index(alias: false, suffix: 'v2')['acknowledged']).to eq(true)
        expect(DummiesIndex.elasticsearch.indices).to match_array([])
        expect(DummiesIndex.elasticsearch.aliases).to eq([])
      end
    end
  end
end
