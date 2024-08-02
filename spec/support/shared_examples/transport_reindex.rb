# frozen_string_literal: true

RSpec.shared_examples 'transport#reindex' do |doc_type: false|
  let(:params) do
    doc_type ? { type: 'geo' } : {}
  end
  let(:body) do
    {
      settings: {
        index: {
          number_of_shards: 1,
          number_of_replicas: 0
        }
      }
    }
  end

  it 'raises an Esse::Transport::ReadonlyClusterError exception when the cluster is readonly' do
    es_client do |client, _conf, cluster|
      cluster.warm_up!
      expect(client).not_to receive(:perform_request)
      cluster.readonly = true
      expect {
        cluster.api.reindex(**params, body: { source: { index: "#{cluster.index_prefix}_ro_from" }, dest: { index: "#{cluster.index_prefix}_ro_to" } })
      }.to raise_error(Esse::Transport::ReadonlyClusterError)
    end
  end

  it 'raises an #<Esse::Transport::NotFoundError exception when the source index does not exist' do
    es_client do |_client, _conf, cluster|
      expect {
        cluster.api.reindex(**params, body: { source: { index: "#{cluster.index_prefix}_non_existent_index" }, dest: { index: "#{cluster.index_prefix}_to" } })
      }.to raise_error(Esse::Transport::NotFoundError)
    end
  end

  context 'when the source index exists' do
    it 'reindexes the source index to the destination index' do
      es_client do |client, _conf, cluster|
        source_index = "#{cluster.index_prefix}_reindex_from"
        dest_index = "#{cluster.index_prefix}_reindex_to"
        cluster.api.create_index(index: source_index, body: body)
        cluster.api.create_index(index: dest_index, body: body)
        cluster.api.index(**params, index: source_index, id: 1, body: { title: 'foo' }, refresh: true)

        resp = nil
        expect {
          resp = cluster.api.reindex(**params, body: { source: { index: source_index }, dest: { index: dest_index } }, refresh: true)
        }.not_to raise_error
        expect(resp['total']).to eq(1)

        resp = cluster.api.get(**params, index: dest_index, id: 1, _source: false)
        expect(resp['found']).to eq(true)
      end
    end
  end
end
