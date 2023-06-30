# frozen_string_literal: true

RSpec.shared_examples 'transport#create_index' do
  let(:body) do
    {
      settings: {
        number_of_shards: 1,
        number_of_replicas: 0
      }
    }
  end
  it 'creates a new index with defined settings' do
    es_client do |client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies"
      resp = nil
      expect {
        resp = cluster.api.create_index(index: index_name, body: body)
      }.not_to raise_error
      expect(resp['acknowledged']).to eq(true)

      resp = client.indices.get_settings(index: index_name)
      expect(resp.dig(index_name, 'settings', 'index', 'number_of_shards')).to eq('1')
      expect(resp.dig(index_name, 'settings', 'index', 'number_of_replicas')).to eq('0')
    end
  end

  it 'creates a new index and wait for configured global status' do
    es_client do |client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies"
      expect(cluster).to receive(:wait_for_status!).with(
        status: (cluster.wait_for_status = 'green'),
        index: index_name,
      ).and_call_original
      resp = nil

      expect {
        resp = cluster.api.create_index(index: index_name, body: body)
      }.not_to raise_error
      expect(resp['acknowledged']).to eq(true)
    end
  end

  it 'creates a new index and wait for given status' do
    es_client do |client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies"
      expect(cluster).to receive(:wait_for_status!).with(
        status: 'green',
        index: index_name,
      ).and_call_original
      resp = nil

      expect {
        resp = cluster.api.create_index(index: index_name, body: body, wait_for_status: 'green')
      }.not_to raise_error
      expect(resp['acknowledged']).to eq(true)
    end
  end

  it 'raises an exeption when api throws an error' do
    es_client do |client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies"
      cluster.api.create_index(index: index_name, body: body)

      expect {
        cluster.api.create_index(index: index_name, body: body)
      }.to raise_error(Esse::Transport::BadRequestError)
    end
  end
end
