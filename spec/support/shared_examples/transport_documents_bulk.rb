# frozen_string_literal: true

RSpec.shared_examples 'transport#bulk' do
  let(:index_suffix) { SecureRandom.hex(8) }

  it 'raises an Esse::Transport::ReadonlyClusterError exception when the cluster is readonly' do
    es_client do |client, _conf, cluster|
      cluster.warm_up!
      expect(client).not_to receive(:perform_request)
      cluster.readonly = true
      expect {
        cluster.api.bulk(index: "#{cluster.index_prefix}_readonly", body: [])
      }.to raise_error(Esse::Transport::ReadonlyClusterError)
    end
  end

  it 'indexes documents in bulk mode using a String as the payload' do
    es_client do |_client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies_#{index_suffix}"
      cluster.api.create_index(index: index_name, body: {
        settings: { index: { number_of_shards: 1, number_of_replicas: 0 } },
      })

      payload = <<~PAYLOAD
        {"index":{"_index":"#{index_name}","_id":"1"}}
        {"title":"1"}
        {"index":{"_index":"#{index_name}","_id":"2"}}
        {"title":"Two"}
        {"update":{"_index":"#{index_name}","_id":"1"}}
        {"doc":{"title":"One"}}
        {"delete":{"_index":"#{index_name}","_id":"2"}}
      PAYLOAD

      resp = nil
      expect {
        resp = cluster.api.bulk(index: index_name, body: payload)
      }.not_to raise_error
      expect(resp['errors']).to eq(false)
      expect(resp['items'].size).to eq(4)
    end
  end

  it 'indexes documents in bulk mode using an Array as the payload' do
    es_client do |_client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies_#{index_suffix}"
      cluster.api.create_index(index: index_name, body: {
        settings: { index: { number_of_shards: 1, number_of_replicas: 0 } },
      })

      payload = [
        { index: { _index: index_name, _id: 1 } },
        { title: '1' },
        { index: { _index: index_name, _id: 2 } },
        { title: 'Two' },
        { update: { _index: index_name, _id: 1 } },
        { doc: { title: 'One' } },
        { delete: { _index: index_name, _id: 2 } },
      ]

      resp = nil
      expect {
        resp = cluster.api.bulk(index: index_name, body: payload)
      }.not_to raise_error
      expect(resp['errors']).to eq(false)
      expect(resp['items'].size).to eq(4)
    end
  end

  it 'indexes documents in bulk mode using array with hash :data as the payload' do
    es_client do |_client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies_#{index_suffix}"
      cluster.api.create_index(index: index_name, body: {
        settings: { index: { number_of_shards: 1, number_of_replicas: 0 } },
      })

      payload = [
        { index: { _index: index_name, _id: 1, data: { title: '1' } } },
        { index: { _index: index_name, _id: 2, data: { title: 'Two' } } },
        { update: { _index: index_name, _id: 1, data: { doc: { title: 'One' } } } },
        { delete: { _index: index_name, _id: 2 } },
      ]

      resp = nil
      expect {
        resp = cluster.api.bulk(index: index_name, body: payload)
      }.not_to raise_error
      expect(resp['errors']).to eq(false)
      expect(resp['items'].size).to eq(4)
    end
  end

  it 'creates an index when the index does not exist along with bulk indexing' do
    es_client do |_client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies_#{index_suffix}"

      resp = nil
      expect {
        resp = cluster.api.bulk(index: index_name, body: [
          { index: { _index: index_name, _id: 1 } },
          { title: '1' },
        ])
      }.not_to raise_error
      expect(resp['errors']).to eq(false)
    end
  end

  it 'raises an error when performing bulk with an empty payload' do
    es_client do |_client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies_#{index_suffix}"

      expect {
        cluster.api.bulk(index: index_name, body: [])
      }.to raise_error(Esse::Transport::BadRequestError)
    end
  end
end
