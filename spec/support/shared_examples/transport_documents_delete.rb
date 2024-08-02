# frozen_string_literal: true

RSpec.shared_examples 'transport#delete' do |doc_type: false|
  let(:params) do
    doc_type ? { type: 'geo' } : {}
  end
  let(:index_suffix) { SecureRandom.hex(8) }

  it 'raises an Esse::Transport::ReadonlyClusterError exception when the cluster is readonly' do
    es_client do |client, _conf, cluster|
      cluster.warm_up!
      expect(client).not_to receive(:perform_request)
      cluster.readonly = true
      expect {
        cluster.api.delete(index: "#{cluster.index_prefix}_readonly", id: 1, **params)
      }.to raise_error(Esse::Transport::ReadonlyClusterError)
    end
  end

  it 'deletes an existing document' do
    es_client do |_client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies_#{index_suffix}"
      cluster.api.create_index(index: index_name, body: {
        settings: { index: { number_of_shards: 1, number_of_replicas: 0 } },
      })
      cluster.api.index(index: index_name, id: 1, body: { name: 'Illinois', pk: 1 }, **params)

      resp = nil
      expect {
        resp = cluster.api.delete(index: index_name, id: 1, **params)
      }.not_to raise_error
      expect(resp['_index']).to eq(index_name)
      expect(resp['_id']).to eq('1')
    end
  end

  it 'raises an error when document does not exist' do
    es_client do |_client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies_#{index_suffix}"
      cluster.api.create_index(index: index_name, body: {
        settings: { index: { number_of_shards: 1, number_of_replicas: 0 } },
      })

      expect {
        cluster.api.delete(index: index_name, id: 1, **params)
      }.to raise_error(Esse::Transport::NotFoundError)
    end
  end
end
