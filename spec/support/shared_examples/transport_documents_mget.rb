# frozen_string_literal: true

RSpec.shared_examples 'transport#mget' do |doc_type: false|
  let(:params) do
    doc_type ? { type: 'geo' } : {}
  end
  let(:index_suffix) { SecureRandom.hex(8) }

  it 'retrieves multiple existing documents' do
    es_client do |_client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies_#{index_suffix}"
      cluster.api.create_index(index: index_name, body: {
        settings: { index: { number_of_shards: 1, number_of_replicas: 0 } },
      })
      cluster.api.index(index: index_name, id: 1, body: { name: 'Illinois', pk: 1 }, refresh: true, **params)
      cluster.api.index(index: index_name, id: 2, body: { name: 'New York', pk: 2 }, refresh: true, **params)

      resp = nil
      expect {
        resp = cluster.api.mget(index: index_name, body: { ids: [1, 2] })
      }.not_to raise_error
      expect(resp['docs'].size).to eq(2)
      expect(resp['docs'].map { |d| d['_id'] }).to match_array(%w[1 2])
      expect(resp['docs'].all? { |d| d['found'] }).to eq(true)
    end
  end

  it 'returns found: false for missing document IDs' do
    es_client do |_client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies_#{index_suffix}"
      cluster.api.create_index(index: index_name, body: {
        settings: { index: { number_of_shards: 1, number_of_replicas: 0 } },
      })
      cluster.api.index(index: index_name, id: 1, body: { name: 'Illinois', pk: 1 }, refresh: true, **params)

      resp = cluster.api.mget(index: index_name, body: { ids: [1, 999] })
      found_doc = resp['docs'].find { |d| d['_id'] == '1' }
      missing_doc = resp['docs'].find { |d| d['_id'] == '999' }

      expect(found_doc['found']).to eq(true)
      expect(missing_doc['found']).to eq(false)
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
        cluster.api.mget(index: index_name, body: { ids: [1] })
      }.not_to raise_error
    end
  end
end
