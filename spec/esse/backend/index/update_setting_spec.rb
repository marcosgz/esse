# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Backend::Index do
  before do
    stub_index(:dummies) do
      settings do
        {
          'refresh_interval' => '1s',
        }
      end
    end
  end

  describe '.update_settings!' do
    specify do
      es_client do |client, _conf, cluster|
        expect{ DummiesIndex.backend.update_settings! }.to raise_error(
          Elasticsearch::Transport::Transport::Errors::NotFound,
        ).with_message(/\[#{cluster.index_prefix}_dummies\] missing/)
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect{ DummiesIndex.backend.update_settings!(suffix: 'v1', ) }.to raise_error(
          Elasticsearch::Transport::Transport::Errors::NotFound,
        ).with_message(/\[#{cluster.index_prefix}_dummies_v1\] missing/)
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.backend.create_index(alias: true, suffix: 'v1')['acknowledged']).to eq(true)
        settings = client.indices.get_settings(index: "#{cluster.index_prefix}_dummies")
        expect(settings.dig("#{cluster.index_prefix}_dummies_v1", 'settings', 'index', 'number_of_replicas')).to eq('0')
        expect(settings.dig("#{cluster.index_prefix}_dummies_v1", 'settings', 'index', 'refresh_interval')).to eq('1s')

        new_setting = instance_double(
          Esse::IndexSetting,
          body: {
            'number_of_shards' => 2,
          },
        )
        expect(DummiesIndex).to receive(:setting).and_return(new_setting)
        expect{ DummiesIndex.backend.update_settings! }.to raise_error(
          Elasticsearch::Transport::Transport::Errors::BadRequest,
        ).with_message(/can't change the number of shards for an index/)
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.backend.create_index(alias: true, suffix: 'v1')['acknowledged']).to eq(true)
        settings = client.indices.get_settings(index: "#{cluster.index_prefix}_dummies")
        expect(settings.dig("#{cluster.index_prefix}_dummies_v1", 'settings', 'index', 'number_of_replicas')).to eq('0')
        expect(settings.dig("#{cluster.index_prefix}_dummies_v1", 'settings', 'index', 'refresh_interval')).to eq('1s')

        new_setting = instance_double(
          Esse::IndexSetting,
          body: {
            'refresh_interval' => -1,
          },
        )
        expect(DummiesIndex).to receive(:setting).and_return(new_setting)
        expect(DummiesIndex.backend.update_settings!['acknowledged']).to eq(true)

        settings = client.indices.get_settings(index: "#{cluster.index_prefix}_dummies")
        expect(settings.dig("#{cluster.index_prefix}_dummies_v1", 'settings', 'index', 'number_of_replicas')).to eq('0')
        expect(settings.dig("#{cluster.index_prefix}_dummies_v1", 'settings', 'index', 'refresh_interval')).to eq('-1')

        v1_state = client.cluster
          .state(index: "#{cluster.index_prefix}_dummies_v1", metric: 'metadata')
          .dig('metadata', 'indices', "#{cluster.index_prefix}_dummies_v1", 'state')
        expect(v1_state).to eq('open')
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.backend.create_index(alias: true, suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.create_index(alias: false, suffix: 'v2')['acknowledged']).to eq(true)
        settings = client.indices.get_settings(index: "#{cluster.index_prefix}_dummies*")
        expect(settings.dig("#{cluster.index_prefix}_dummies_v1", 'settings', 'index', 'refresh_interval')).to eq('1s')
        expect(settings.dig("#{cluster.index_prefix}_dummies_v2", 'settings', 'index', 'refresh_interval')).to eq('1s')

        new_setting = instance_double(
          Esse::IndexSetting,
          body: {
            'refresh_interval' => -1,
          },
        )
        expect(DummiesIndex).to receive(:setting).and_return(new_setting)
        expect(DummiesIndex.backend.update_settings!(suffix: 'v2')['acknowledged']).to eq(true)

        settings = client.indices.get_settings(index: "#{cluster.index_prefix}_dummies*")
        expect(settings.dig("#{cluster.index_prefix}_dummies_v1", 'settings', 'index', 'refresh_interval')).to eq('1s')
        expect(settings.dig("#{cluster.index_prefix}_dummies_v2", 'settings', 'index', 'refresh_interval')).to eq('-1')

        v2_state = client.cluster
          .state(index: "#{cluster.index_prefix}_dummies_v2", metric: 'metadata')
          .dig('metadata', 'indices', "#{cluster.index_prefix}_dummies_v2", 'state')
        expect(v2_state).to eq('open')
      end
    end
  end

  describe '.update_settings' do
    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.backend.update_settings).to eq(false)
      end
    end
  
    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.backend.update_settings(suffix: 'v1')).to eq(false)
      end
    end
  
    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.backend.create_index(alias: true, suffix: 'v1')['acknowledged']).to eq(true)
        settings = client.indices.get_settings(index: "#{cluster.index_prefix}_dummies")
        expect(settings.dig("#{cluster.index_prefix}_dummies_v1", 'settings', 'index', 'number_of_replicas')).to eq('0')
        expect(settings.dig("#{cluster.index_prefix}_dummies_v1", 'settings', 'index', 'refresh_interval')).to eq('1s')
  
        new_setting = instance_double(
          Esse::IndexSetting,
          body: {
            'number_of_shards' => 2,
          },
        )
        expect(DummiesIndex).to receive(:setting).and_return(new_setting)
        expect(DummiesIndex.backend.update_settings).to eq(false)
      end
    end
  
    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.backend.create_index(alias: true, suffix: 'v1')['acknowledged']).to eq(true)
        settings = client.indices.get_settings(index: "#{cluster.index_prefix}_dummies")
        expect(settings.dig("#{cluster.index_prefix}_dummies_v1", 'settings', 'index', 'number_of_replicas')).to eq('0')
        expect(settings.dig("#{cluster.index_prefix}_dummies_v1", 'settings', 'index', 'refresh_interval')).to eq('1s')
  
        new_setting = instance_double(
          Esse::IndexSetting,
          body: {
            'refresh_interval' => -1,
          },
        )
        expect(DummiesIndex).to receive(:setting).and_return(new_setting)
        expect(DummiesIndex.backend.update_settings['acknowledged']).to eq(true)
  
        settings = client.indices.get_settings(index: "#{cluster.index_prefix}_dummies")
        expect(settings.dig("#{cluster.index_prefix}_dummies_v1", 'settings', 'index', 'number_of_replicas')).to eq('0')
        expect(settings.dig("#{cluster.index_prefix}_dummies_v1", 'settings', 'index', 'refresh_interval')).to eq('-1')
  
        v1_state = client.cluster
          .state(index: "#{cluster.index_prefix}_dummies_v1", metric: 'metadata')
          .dig('metadata', 'indices', "#{cluster.index_prefix}_dummies_v1", 'state')
        expect(v1_state).to eq('open')
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.backend.create_index(alias: true, suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.backend.create_index(alias: false, suffix: 'v2')['acknowledged']).to eq(true)
        settings = client.indices.get_settings(index: "#{cluster.index_prefix}_dummies*")
        expect(settings.dig("#{cluster.index_prefix}_dummies_v1", 'settings', 'index', 'refresh_interval')).to eq('1s')
        expect(settings.dig("#{cluster.index_prefix}_dummies_v2", 'settings', 'index', 'refresh_interval')).to eq('1s')

        new_setting = instance_double(
          Esse::IndexSetting,
          body: {
            'refresh_interval' => -1,
          },
        )
        expect(DummiesIndex).to receive(:setting).and_return(new_setting)
        expect(DummiesIndex.backend.update_settings(suffix: 'v2')['acknowledged']).to eq(true)

        settings = client.indices.get_settings(index: "#{cluster.index_prefix}_dummies*")
        expect(settings.dig("#{cluster.index_prefix}_dummies_v1", 'settings', 'index', 'refresh_interval')).to eq('1s')
        expect(settings.dig("#{cluster.index_prefix}_dummies_v2", 'settings', 'index', 'refresh_interval')).to eq('-1')

        v2_state = client.cluster
          .state(index: "#{cluster.index_prefix}_dummies_v2", metric: 'metadata')
          .dig('metadata', 'indices', "#{cluster.index_prefix}_dummies_v2", 'state')
        expect(v2_state).to eq('open')
      end
    end
  end
end
