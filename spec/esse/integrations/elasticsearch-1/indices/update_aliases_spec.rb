# frozen_string_literal: true

require 'spec_helper'

stack_describe 'elasticsearch', '1.x', 'elasticsearch update aliases' do
  before do
    stub_index(:dummies)
  end

  describe '.update_aliases' do
    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.elasticsearch.update_aliases(suffix: 'v1')).to eq('errors' => true)
        expect(DummiesIndex.elasticsearch.create_index(alias: false, suffix: 'v1')['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies")).to eq(false)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v1")).to eq(true)
        expect(DummiesIndex.elasticsearch.update_aliases(suffix: 'v1')['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies")).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v1")).to eq(true)
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.elasticsearch.create_index(alias: false, suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.elasticsearch.create_index(alias: true, suffix: 'v2')['acknowledged']).to eq(true)
        expect(DummiesIndex.elasticsearch.create_index(alias: false, suffix: 'v3')['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies")).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v1")).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v2")).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v3")).to eq(true)
        expect(client.indices.get_alias(index: "#{cluster.index_prefix}_dummies")).to eq(
          "#{cluster.index_prefix}_dummies_v2" => {
            'aliases' => {
              "#{cluster.index_prefix}_dummies" => {},
            },
          },
        )
        expect(DummiesIndex.elasticsearch.update_aliases(suffix: 'v3')['acknowledged']).to eq(true)
        expect(client.indices.get_alias(index: "#{cluster.index_prefix}_dummies")).to eq(
          "#{cluster.index_prefix}_dummies_v3" => {
            'aliases' => {
              "#{cluster.index_prefix}_dummies" => {},
            },
          },
        )
      end
    end
  end

  describe '.update_aliases!' do
    specify do
      es_client do |client, _conf, cluster|
        expect { DummiesIndex.elasticsearch.update_aliases!(suffix: 'v1') }.to raise_error(
          Esse::Transport::NotFoundError,
        ).with_message(/\[#{cluster.index_prefix}_dummies_v1\] missing/)
        expect(DummiesIndex.elasticsearch.create_index(alias: false, suffix: 'v1')['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies")).to eq(false)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v1")).to eq(true)
        expect(DummiesIndex.elasticsearch.update_aliases!(suffix: 'v1')['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies")).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v1")).to eq(true)
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.elasticsearch.create_index(alias: false, suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.elasticsearch.create_index(alias: true, suffix: 'v2')['acknowledged']).to eq(true)
        expect(DummiesIndex.elasticsearch.create_index(alias: false, suffix: 'v3')['acknowledged']).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies")).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v1")).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v2")).to eq(true)
        expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v3")).to eq(true)
        expect(client.indices.get_alias(index: "#{cluster.index_prefix}_dummies")).to eq(
          "#{cluster.index_prefix}_dummies_v2" => {
            'aliases' => {
              "#{cluster.index_prefix}_dummies" => {},
            },
          },
        )
        expect(DummiesIndex.elasticsearch.update_aliases!(suffix: 'v3')['acknowledged']).to eq(true)
        expect(client.indices.get_alias(index: "#{cluster.index_prefix}_dummies")).to eq(
          "#{cluster.index_prefix}_dummies_v3" => {
            'aliases' => {
              "#{cluster.index_prefix}_dummies" => {},
            },
          },
        )
      end
    end
  end
end
