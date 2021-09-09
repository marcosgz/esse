# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "[ES #{ENV.fetch("STACK_VERSION", "1.x")}] close index", es_version: '1.x' do
  before do
    stub_index(:dummies)
  end

  describe '.close!' do
    specify do
      es_client do |client, _conf, cluster|
        expect { DummiesIndex.elasticsearch.close! }.to raise_error(
          Elasticsearch::Transport::Transport::Errors::NotFound,
        ).with_message(/\[#{cluster.index_prefix}_dummies\] missing/)
        expect(DummiesIndex.elasticsearch.create_index(alias: true, suffix: 'v1')['acknowledged']).to eq(true)
        client.cluster.health(wait_for_status: 'green')
        expect(DummiesIndex.elasticsearch.close!['acknowledged']).to eq(true)
        expected_state = client.cluster.state(index: DummiesIndex.index_name, metric: 'metadata')
        expect(
          expected_state.dig('metadata', 'indices', "#{cluster.index_prefix}_dummies_v1", 'state'),
        ).to eq('close')
        expect(DummiesIndex.elasticsearch.close!['acknowledged']).to eq(true)
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect { DummiesIndex.elasticsearch.close!(suffix: 'v2') }.to raise_error(
          Elasticsearch::Transport::Transport::Errors::NotFound,
        ).with_message(/\[#{cluster.index_prefix}_dummies_v2\] missing/)
        expect(DummiesIndex.elasticsearch.create_index(alias: true, suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.elasticsearch.create_index(alias: false, suffix: 'v2')['acknowledged']).to eq(true)
        client.cluster.health(wait_for_status: 'green')
        expect(DummiesIndex.elasticsearch.close!(suffix: 'v2')['acknowledged']).to eq(true)

        v1_state = client.cluster
          .state(index: "#{cluster.index_prefix}_dummies_v1", metric: 'metadata')
          .dig('metadata', 'indices', "#{cluster.index_prefix}_dummies_v1", 'state')
        expect(v1_state).to eq('open')

        v2_state = client.cluster.state(index: "#{cluster.index_prefix}_dummies_v2", metric: 'metadata')
          .dig('metadata', 'indices', "#{cluster.index_prefix}_dummies_v2", 'state')

        expect(v2_state).to eq('close')
      end
    end
  end

  describe '.close' do
    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.elasticsearch.close).to eq('errors' => true)
        expect(DummiesIndex.elasticsearch.create_index(alias: true, suffix: 'v1')['acknowledged']).to eq(true)
        client.cluster.health(wait_for_status: 'green')
        expect(DummiesIndex.elasticsearch.close['acknowledged']).to eq(true)
        expected_state = client.cluster.state(index: DummiesIndex.index_name, metric: 'metadata')
        expect(
          expected_state.dig('metadata', 'indices', "#{cluster.index_prefix}_dummies_v1", 'state'),
        ).to eq('close')
        expect(DummiesIndex.elasticsearch.close!['acknowledged']).to eq(true)
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.elasticsearch.close(suffix: 'v2')).to eq('errors' => true)
        expect(DummiesIndex.elasticsearch.create_index(alias: true, suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.elasticsearch.create_index(alias: false, suffix: 'v2')['acknowledged']).to eq(true)
        client.cluster.health(wait_for_status: 'green')
        expect(DummiesIndex.elasticsearch.close(suffix: 'v2')['acknowledged']).to eq(true)

        v1_state = client.cluster
          .state(index: "#{cluster.index_prefix}_dummies_v1", metric: 'metadata')
          .dig('metadata', 'indices', "#{cluster.index_prefix}_dummies_v1", 'state')
        expect(v1_state).to eq('open')

        v2_state = client.cluster.state(index: "#{cluster.index_prefix}_dummies_v2", metric: 'metadata')
          .dig('metadata', 'indices', "#{cluster.index_prefix}_dummies_v2", 'state')

        expect(v2_state).to eq('close')
      end
    end
  end
end
