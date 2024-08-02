# frozen_string_literal: true

RSpec.shared_examples 'transport#update_by_query' do
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
        cluster.api.update_by_query(index: "#{cluster.index_prefix}_redonly", body: { script: { source: 'ctx._source.title = "foo"' } }, q: '*')
      }.to raise_error(Esse::Transport::ReadonlyClusterError)
    end
  end

  it 'raises an #<Esse::Transport::NotFoundError exception when the source index does not exist' do
    es_client do |_client, _conf, cluster|
      expect {
        cluster.api.update_by_query(index: "#{cluster.index_prefix}_non_existent_index", body: { script: { source: 'ctx._source.title = "foo"' }, query: { match_all: {} } })
      }.to raise_error(Esse::Transport::NotFoundError)
    end
  end

  context 'when the index exists' do
    it 'reindexes the source index to the destination index' do
      es_client do |client, _conf, cluster|
        index_name = "#{cluster.index_prefix}_update_by_query"
        cluster.api.create_index(index: index_name, body: body)
        cluster.api.index(index: index_name, id: 1, body: { title: 'old title' }, refresh: true)

        resp = nil
        expect {
          resp = cluster.api.update_by_query(index: index_name, body: { script: { source: 'ctx._source.title = "new title"' }, query: { match_all: {} } })
        }.not_to raise_error
        expect(resp['total']).to eq(1)
        expect(resp['updated']).to eq(1)
      end
    end
  end
end
