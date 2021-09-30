# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "[ES #{ENV.fetch("STACK_VERSION", "1.x")}] open index", es_version: '1.x' do
  before do
    stub_index(:dummies)
  end

  describe '.open!' do
    specify do
      es_client do |_client, _conf, cluster|
        expect { DummiesIndex.elasticsearch.open! }.to raise_error(
          Elasticsearch::Transport::Transport::Errors::NotFound,
        ).with_message(/\[#{cluster.index_prefix}_dummies\] missing/)
      end
    end

    specify do
      es_client do |_client, _conf, cluster|
        expect { DummiesIndex.elasticsearch.open!(suffix: 'v1') }.to raise_error(
          Elasticsearch::Transport::Transport::Errors::NotFound,
        ).with_message(/\[#{cluster.index_prefix}_dummies_v1\] missing/)
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.elasticsearch.create_index(alias: true, suffix: 'v1')['acknowledged']).to eq(true)
        client.cluster.health(wait_for_status: 'green')
        client.indices.close(index: "#{cluster.index_prefix}_dummies_v1")
        expect(DummiesIndex.elasticsearch.open!['acknowledged']).to eq(true)

        v1_state = client.cluster
          .state(index: "#{cluster.index_prefix}_dummies_v1", metric: 'metadata')
          .dig('metadata', 'indices', "#{cluster.index_prefix}_dummies_v1", 'state')
        expect(v1_state).to eq('open')
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.elasticsearch.create_index(alias: true, suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.elasticsearch.create_index(alias: false, suffix: 'v2')['acknowledged']).to eq(true)
        client.cluster.health(wait_for_status: 'green')
        client.indices.close(index: "#{cluster.index_prefix}_dummies_v1,#{cluster.index_prefix}_dummies_v2")
        expect(DummiesIndex.elasticsearch.open!(suffix: 'v2')['acknowledged']).to eq(true)

        v1_state = client.cluster
          .state(index: "#{cluster.index_prefix}_dummies_v1", metric: 'metadata')
          .dig('metadata', 'indices', "#{cluster.index_prefix}_dummies_v1", 'state')
        expect(v1_state).to eq('close')

        v2_state = client.cluster
          .state(index: "#{cluster.index_prefix}_dummies_v2", metric: 'metadata')
          .dig('metadata', 'indices', "#{cluster.index_prefix}_dummies_v2", 'state')
        expect(v2_state).to eq('open')
      end
    end
  end

  describe '.open' do
    specify do
      es_client do |_client, _conf, _cluster|
        expect(DummiesIndex.elasticsearch.open).to eq('errors' => true)
      end
    end

    specify do
      es_client do |_client, _conf, _cluster|
        expect(DummiesIndex.elasticsearch.open(suffix: 'v1')).to eq('errors' => true)
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.elasticsearch.create_index(alias: true, suffix: 'v1')['acknowledged']).to eq(true)
        client.cluster.health(wait_for_status: 'green')
        client.indices.close(index: "#{cluster.index_prefix}_dummies_v1")
        expect(DummiesIndex.elasticsearch.open['acknowledged']).to eq(true)

        v1_state = client.cluster
          .state(index: "#{cluster.index_prefix}_dummies_v1", metric: 'metadata')
          .dig('metadata', 'indices', "#{cluster.index_prefix}_dummies_v1", 'state')
        expect(v1_state).to eq('open')
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.elasticsearch.create_index(alias: true, suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.elasticsearch.create_index(alias: false, suffix: 'v2')['acknowledged']).to eq(true)
        client.cluster.health(wait_for_status: 'green')
        client.indices.close(index: "#{cluster.index_prefix}_dummies_v1,#{cluster.index_prefix}_dummies_v2")
        expect(DummiesIndex.elasticsearch.open(suffix: 'v2')['acknowledged']).to eq(true)

        v1_state = client.cluster
          .state(index: "#{cluster.index_prefix}_dummies_v1", metric: 'metadata')
          .dig('metadata', 'indices', "#{cluster.index_prefix}_dummies_v1", 'state')
        expect(v1_state).to eq('close')

        v2_state = client.cluster
          .state(index: "#{cluster.index_prefix}_dummies_v2", metric: 'metadata')
          .dig('metadata', 'indices', "#{cluster.index_prefix}_dummies_v2", 'state')
        expect(v2_state).to eq('open')
      end
    end
  end
end
