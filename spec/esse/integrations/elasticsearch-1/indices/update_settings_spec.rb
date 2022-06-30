# frozen_string_literal: true

require 'spec_helper'

stack_describe 'elasticsearch', '1.x', 'elasticsearch update settings' do
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
      es_client do |_client, _conf, cluster|
        expect { DummiesIndex.elasticsearch.update_settings! }.to raise_error(
          Esse::Backend::NotFoundError,
        ).with_message(/\[#{cluster.index_prefix}_dummies\] missing/)
      end
    end

    specify do
      es_client do |_client, _conf, cluster|
        expect { DummiesIndex.elasticsearch.update_settings!(suffix: 'v1') }.to raise_error(
          Esse::Backend::NotFoundError,
        ).with_message(/\[#{cluster.index_prefix}_dummies_v1\] missing/)
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.elasticsearch.create_index(alias: true, suffix: 'v1')['acknowledged']).to eq(true)
        settings = client.indices.get_settings(index: "#{cluster.index_prefix}_dummies")
        expect(settings.dig("#{cluster.index_prefix}_dummies_v1", 'settings', 'index', 'number_of_replicas')).to eq('0')
        expect(settings.dig("#{cluster.index_prefix}_dummies_v1", 'settings', 'index', 'refresh_interval')).to eq('1s')

        new_setting = instance_double(
          Esse::IndexSetting,
          body: {
            'some_invalid_setting' => 2,
          },
        )
        expect(DummiesIndex).to receive(:setting).and_return(new_setting)
        expect { DummiesIndex.elasticsearch.update_settings! }.to raise_error(
          Esse::Backend::BadRequestError,
        ).with_message(/index.some_invalid_setting/)
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.elasticsearch.create_index(alias: true, suffix: 'v1')['acknowledged']).to eq(true)
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
        expect(DummiesIndex.elasticsearch.update_settings!['acknowledged']).to eq(true)

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
        expect(DummiesIndex.elasticsearch.create_index(alias: true, suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.elasticsearch.create_index(alias: false, suffix: 'v2')['acknowledged']).to eq(true)
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
        expect(DummiesIndex.elasticsearch.update_settings!(suffix: 'v2')['acknowledged']).to eq(true)

        settings = client.indices.get_settings(index: "#{cluster.index_prefix}_dummies*")
        expect(settings.dig("#{cluster.index_prefix}_dummies_v1", 'settings', 'index', 'refresh_interval')).to eq('1s')
        expect(settings.dig("#{cluster.index_prefix}_dummies_v2", 'settings', 'index', 'refresh_interval')).to eq('-1')

        v2_state = client.cluster
          .state(index: "#{cluster.index_prefix}_dummies_v2", metric: 'metadata')
          .dig('metadata', 'indices', "#{cluster.index_prefix}_dummies_v2", 'state')
        expect(v2_state).to eq('open')
      end
    end

    it 'closes index, update analysis and opens index again' do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.elasticsearch.create_index(alias: true, suffix: 'v1')).to eq('acknowledged' => true)
        response = client.indices.get_settings(index: "#{cluster.index_prefix}_dummies*")
        expect(response.dig("#{cluster.index_prefix}_dummies_v1", 'settings', 'index', 'analysis')).to eq(nil)

        DummiesIndex.instance_variable_set(:@setting, nil)
        DummiesIndex.settings do
          {
            analysis: {
              analyzer: {
                remove_html: {
                  type: :custom,
                  char_filter: :html_strip,
                }
              }
            }
          }
        end
        expect(DummiesIndex.settings_hash.dig('settings', :analysis, :analyzer, :remove_html)).not_to eq(nil)
        expect(DummiesIndex.elasticsearch.update_settings!(suffix: 'v1')).to eq('acknowledged' => true)

        response = client.indices.get_settings(index: "#{cluster.index_prefix}_dummies*")
        expect(response.dig("#{cluster.index_prefix}_dummies_v1", 'settings', 'index', 'analysis', 'analyzer').keys).to include('remove_html')

        response = client.cluster.state(index: "#{cluster.index_prefix}_dummies_v1", metric: 'metadata')
        expect(response.dig('metadata', 'indices', "#{cluster.index_prefix}_dummies_v1", 'state')).to eq('open')
      end
    end
  end

  describe '.update_settings' do
    specify do
      es_client do |_client, _conf, _cluster|
        expect(DummiesIndex.elasticsearch.update_settings).to eq('errors' => true)
      end
    end

    specify do
      es_client do |_client, _conf, _cluster|
        expect(DummiesIndex.elasticsearch.update_settings(suffix: 'v1')).to eq('errors' => true)
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.elasticsearch.create_index(alias: true, suffix: 'v1')['acknowledged']).to eq(true)
        settings = client.indices.get_settings(index: "#{cluster.index_prefix}_dummies")
        expect(settings.dig("#{cluster.index_prefix}_dummies_v1", 'settings', 'index', 'number_of_replicas')).to eq('0')
        expect(settings.dig("#{cluster.index_prefix}_dummies_v1", 'settings', 'index', 'refresh_interval')).to eq('1s')

        new_setting = instance_double(
          Esse::IndexSetting,
          body: {
            'some_invalid_setting' => -1,
          },
        )
        expect(DummiesIndex).to receive(:setting).and_return(new_setting)
        expect(DummiesIndex.elasticsearch.update_settings).to eq('errors' => true)
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.elasticsearch.create_index(alias: true, suffix: 'v1')['acknowledged']).to eq(true)
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
        expect(DummiesIndex.elasticsearch.update_settings['acknowledged']).to eq(true)

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
        expect(DummiesIndex.elasticsearch.create_index(alias: true, suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.elasticsearch.create_index(alias: false, suffix: 'v2')['acknowledged']).to eq(true)
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
        expect(DummiesIndex.elasticsearch.update_settings(suffix: 'v2')['acknowledged']).to eq(true)

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
