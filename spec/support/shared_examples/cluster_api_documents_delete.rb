# frozen_string_literal: true

RSpec.shared_examples 'cluster_api#delete' do |doc_type: false|
  let(:params) do
    doc_type ? { type: 'geo' } : {}
  end

  it 'deletes an existing document' do
    es_client do |_client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies_#{SecureRandom.hex(8)}}"
      cluster.api.create_index(index: index_name, body: {
        settings: { number_of_shards: 1, number_of_replicas: 0 },
      })
      cluster.api.index(index: index_name, id: 1, body: { name: 'Illinois', pk: 1 }, **params)

      resp = nil
      expect {
        resp = cluster.api.delete(index: index_name, id: 1, **params)
      }.not_to raise_error
      expect(resp['_index']).to eq(index_name)
      expect(resp['_version']).to eq(2)
      expect(resp['_id']).to eq('1')
    end
  end

  it 'raises an error when document does not exist' do
    es_client do |_client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies_#{SecureRandom.hex(8)}}"
      cluster.api.create_index(index: index_name, body: {
        settings: { number_of_shards: 1, number_of_replicas: 0 },
      })

      expect {
        cluster.api.delete(index: index_name, id: 1, **params)
      }.to raise_error(Esse::Transport::NotFoundError)
    end
  end
end
