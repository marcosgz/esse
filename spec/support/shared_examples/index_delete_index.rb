# frozen_string_literal: true

RSpec.shared_examples 'index.delete_index' do
  include_context 'with venues index definition'

  let(:index_suffix) { SecureRandom.hex(8) }

  it 'raises an Esse::Transport::ReadonlyClusterError exception when the cluster is readonly' do
    es_client do |client, _conf, cluster|
      cluster.warm_up!
      expect(client).not_to receive(:perform_request)
      cluster.readonly = true
      expect {
        VenuesIndex.delete_index(suffix: index_suffix)
      }.to raise_error(Esse::Transport::ReadonlyClusterError)
    end
  end

  it 'raises an Esse::Transport::ServerError exception when api throws an error' do
    es_client do |client, _conf, cluster|
      expect {
        VenuesIndex.delete_index(suffix: index_suffix)
      }.to raise_error(Esse::Transport::ServerError)
    end
  end

  it 'deletes the aliased index' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: true, suffix: index_suffix)

      resp = nil
      expect {
        resp = VenuesIndex.delete_index
      }.not_to raise_error
      expect(resp['acknowledged']).to eq(true)
      expect(cluster.api.index_exist?(index: VenuesIndex.index_name(suffix: index_suffix))).to eq(false)
    end
  end

  it 'deletes the unaliased index' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: false, suffix: index_suffix)

      resp = nil
      expect {
        resp = VenuesIndex.delete_index(suffix: index_suffix)
      }.not_to raise_error
      expect(resp['acknowledged']).to eq(true)
      expect(cluster.api.index_exist?(index: VenuesIndex.index_name(suffix: index_suffix))).to eq(false)
    end
  end

  it 'deletes the index created with root naming' do
    es_client do |client, _conf, cluster|
      cluster.api.create_index(index: VenuesIndex.index_name, body: {
        settings: { number_of_shards: 1, number_of_replicas: 0 },
      })

      resp = nil
      expect {
        resp = VenuesIndex.delete_index
      }.not_to raise_error
      expect(resp['acknowledged']).to eq(true)
      expect(cluster.api.index_exist?(index: VenuesIndex.index_name)).to eq(false)
    end
  end
end
