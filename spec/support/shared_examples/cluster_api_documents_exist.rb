# frozen_string_literal: true

RSpec.shared_examples 'cluster_api#exist?' do
  it 'checks if a document exists' do
    es_client do |_client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies_#{SecureRandom.hex(8)}}"
      cluster.api.create_index(index: index_name, body: {
        settings: { number_of_shards: 1, number_of_replicas: 0 },
      })
      cluster.api.index(index: index_name, id: 1, body: { name: 'Illinois', pk: 1 })

      resp = nil
      expect {
        resp = cluster.api.exist?(index: index_name, id: 1)
      }.not_to raise_error
      expect(resp).to eq(true)
    end
  end

  it 'does not raises an error when the document does not exist' do
    es_client do |_client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies_#{SecureRandom.hex(8)}}"
      cluster.api.create_index(index: index_name, body: {
        settings: { number_of_shards: 1, number_of_replicas: 0 },
      })

      resp = nil
      expect {
        resp = cluster.api.exist?(index: index_name, id: 1)
      }.not_to raise_error
      expect(resp).to eq(false)
    end
  end

  it 'does not raises an error when the index does not exist' do
    es_client do |_client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies_#{SecureRandom.hex(8)}}"

      resp = nil
      expect {
        resp = cluster.api.exist?(index: index_name, id: 1)
      }.not_to raise_error
      expect(resp).to eq(false)
    end
  end
end
