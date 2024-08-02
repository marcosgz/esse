# frozen_string_literal: true

RSpec.shared_examples 'transport#get' do |doc_type: false|
  let(:params) do
    doc_type ? { type: 'geo' } : {}
  end
  let(:index_suffix) { SecureRandom.hex(8) }

  it 'retrieves an existing document' do
    es_client do |_client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies_#{index_suffix}"
      cluster.api.create_index(index: index_name, body: {
        settings: { index: { number_of_shards: 1, number_of_replicas: 0 } },
      })
      cluster.api.index(index: index_name, id: 1, body: { name: 'Illinois', pk: 1 }, refresh: true, **params)

      resp = nil
      expect {
        resp = cluster.api.get(index: index_name, id: 1)
      }.not_to raise_error
      expect(resp['_index']).to eq(index_name)
      expect(resp['_version']).to eq(1)
      expect(resp['_id']).to eq('1')
      expect(resp['_source']).to eq('name' => 'Illinois', 'pk' => 1)
    end
  end

  it 'raises an error when the index does not exist' do
    es_client do |_client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies_#{index_suffix}"

      expect {
        cluster.api.get(index: index_name, id: 1, **params)
      }.to raise_error(Esse::Transport::NotFoundError)
    end
  end

  it 'does not raise Esse::Transport::ReadonlyClusterError error when the cluster is readonly' do
    es_client do |_client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies_#{index_suffix}"
      cluster.api.create_index(index: index_name, body: {
        settings: { index: { number_of_shards: 1, number_of_replicas: 0 } },
      })
      cluster.api.index(index: index_name, id: 1, body: { name: 'Illinois', pk: 1 }, refresh: true, **params)

      cluster.readonly = true
      expect {
        cluster.api.get(index: index_name, id: 1)
      }.not_to raise_error
    end
  end
end
