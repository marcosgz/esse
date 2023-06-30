# frozen_string_literal: true

RSpec.shared_examples 'transport#count' do |doc_type: false|
  let(:params) do
    doc_type ? { type: 'geo' } : {}
  end

  it 'checks the number of documents in an index' do
    es_client do |_client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies_#{SecureRandom.hex(8)}}"
      cluster.api.create_index(index: index_name, body: {
        settings: { number_of_shards: 1, number_of_replicas: 0 },
      })
      cluster.api.index(index: index_name, id: 1, body: { name: 'Illinois', pk: 1 }, refresh: true, **params)

      resp = nil
      expect {
        resp = cluster.api.count(index: index_name, **params)
      }.not_to raise_error
      expect(resp['count']).to eq(1)
    end
  end

  it 'raises an error when the index does not exist' do
    es_client do |_client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies_#{SecureRandom.hex(8)}}"

      expect {
        cluster.api.count(index: index_name, **params)
      }.to raise_error(Esse::Transport::NotFoundError)
    end
  end
end
