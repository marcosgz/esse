# frozen_string_literal: true

RSpec.shared_examples 'cluster_api#index' do
  it 'indexes a document' do
    es_client do |_client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies_#{SecureRandom.hex(8)}}"
      cluster.api.create_index(index: index_name, body: {
        settings: { number_of_shards: 1, number_of_replicas: 0 },
      })
      resp = nil
      expect {
        resp = cluster.api.index(index: index_name, id: 1, body: { name: 'Illinois', pk: 1 })
      }.not_to raise_error
      expect(resp['_index']).to eq(index_name)
      expect(resp['_version']).to eq(1)
      expect(resp['_id']).to eq('1')
    end
  end
end
