# frozen_string_literal: true

RSpec.shared_examples 'transport#refresh' do
  it 'raises an Esse::Transport::ReadonlyClusterError exception when the cluster is readonly' do
    es_client do |client, _conf, cluster|
      cluster.warm_up!
      expect(client).not_to receive(:perform_request)
      cluster.readonly = true
      expect {
        cluster.api.refresh(index: "#{cluster.index_prefix}_readonly")
      }.to raise_error(Esse::Transport::ReadonlyClusterError)
    end
  end

  it 'raises an Esse::Transport::ServerError exception when api throws an error' do
    es_client do |client, _conf, cluster|
      expect {
        cluster.api.refresh(index: 'esse_unknow_index_name_v1')
      }.to raise_error(Esse::Transport::ServerError)
    end
  end

  it 'refreshes an index' do
    es_client do |client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies_v1"
      cluster.api.create_index(index: index_name, body: {
        settings: { index: { number_of_shards: 1, number_of_replicas: 0 } },
      })

      resp = nil
      expect {
        resp = cluster.api.refresh(index: index_name)
      }.not_to raise_error
      expect(resp).to be_a(Hash)
    end
  end
end
