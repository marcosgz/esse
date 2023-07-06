# frozen_string_literal: true

RSpec.shared_examples 'transport#update_settings' do
  it 'raises an Esse::Transport::ReadonlyClusterError exception when the cluster is readonly' do
    es_client do |client, _conf, cluster|
      cluster.warm_up!
      expect(client).not_to receive(:perform_request)
      cluster.readonly = true
      expect {
        cluster.api.update_settings(index: "#{cluster.index_prefix}_readonly", body: {})
      }.to raise_error(Esse::Transport::ReadonlyClusterError)
    end
  end

  it 'raises an Esse::Transport::ServerError exception when api throws an error' do
    es_client do |client, _conf, cluster|
      expect {
        cluster.api.update_settings(index: 'esse_unknow_index_name_v1', body: {})
      }.to raise_error(Esse::Transport::ServerError)
    end
  end

  it 'updates the mapping' do
    es_client do |client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies_v1"
      cluster.api.create_index(index: index_name, body: {
        settings: {
          index: { number_of_shards: 1, number_of_replicas: 0 },
        },
      })

      expect {
        cluster.api.update_settings(index: index_name, body: {
          index: {
            refresh_interval: '50s',
          }
        })
      }.not_to raise_error
      mapping = client.indices.get_settings(index: index_name)
      expect(mapping.dig(index_name, 'settings', 'index', 'refresh_interval')).to eq('50s')
    end
  end
end
