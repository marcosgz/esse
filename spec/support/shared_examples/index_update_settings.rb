# frozen_string_literal: true

RSpec.shared_examples 'index.update_settings' do
  include_context 'with geos index definition'

  before do
    GeosIndex.settings do
      {
        index: { number_of_shards: 1, number_of_replicas: 0 },
      }
    end
  end

  it 'raises an Esse::Transport::ServerError exception when api throws an error' do
    es_client do |client, _conf, cluster|
      expect {
        GeosIndex.update_settings(suffix: '2022')
      }.to raise_error(Esse::Transport::ServerError)
    end
  end

  it 'update settings from index definition' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: false, suffix: '2022')

      GeosIndex.settings do
        {
          index: {
            number_of_shards: 1,
            number_of_replicas: 0,
            refresh_interval: '50s',
          }
        }
      end

      resp = nil
      expect {
        resp = GeosIndex.update_settings(suffix: '2022')
      }.not_to raise_error
      expect(resp['acknowledged']).to eq(true)

      mapping = client.indices.get_settings(index: index_name = GeosIndex.index_name(suffix: '2022'))
      expect(mapping.dig(index_name, 'settings', 'index', 'refresh_interval')).to eq('50s')
    end
  end

  it 'update settings from body argument' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: false, suffix: '2022')

      resp = nil
      expect {
        resp = GeosIndex.update_settings(suffix: '2022', body: {
          index: {
            refresh_interval: '50s',
          }
        })
      }.not_to raise_error
      expect(resp['acknowledged']).to eq(true)

      mapping = client.indices.get_settings(index: index_name = GeosIndex.index_name(suffix: '2022'))
      expect(mapping.dig(index_name, 'settings', 'index', 'refresh_interval')).to eq('50s')
    end
  end

  it 'allows update index analysis by closing and opening index before put settings' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: false, suffix: '2022')

      resp = nil
      expect {
        resp = GeosIndex.update_settings(suffix: '2022', body: {
          analysis: {
            analyzer: {
              remove_html: {
                type: :custom,
                char_filter: :html_strip,
                tokenizer: 'standard',
              }
            }
          }
        })
      }.not_to raise_error
      expect(resp['acknowledged']).to eq(true)

      mapping = client.indices.get_settings(index: index_name = GeosIndex.index_name(suffix: '2022'))
      expect(mapping.dig(index_name, 'settings', 'index', 'analysis', 'analyzer')).to include('remove_html')

      response = client.cluster.state(index:index_name, metric: 'metadata')
      expect(response.dig('metadata', 'indices', index_name, 'state')).to eq('open')
    end
  end
end
