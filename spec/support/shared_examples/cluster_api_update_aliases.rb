# frozen_string_literal: true

RSpec.shared_examples 'cluster_api#update_aliases' do
  it 'raises an Esse::Transport::ServerError exception when api throws an error' do
    es_client do |client, _conf, cluster|
      expect {
        cluster.api.update_aliases(body: { actions: [{ add: { index: 'esse_unknow_index_name_v1', alias: 'esse_unknow_index_name' } }] })
      }.to raise_error(Esse::Transport::ServerError)
    end
  end

  it 'adds an alias to an index' do
    es_client do |client, _conf, cluster|
      cluster.api.create_index(index: "#{cluster.index_prefix}_dummies_v1", body: {
        settings: { number_of_shards: 1, number_of_replicas: 0 },
      })

      expect {
        cluster.api.update_aliases(body: {
          actions: [{ add: { index: "#{cluster.index_prefix}_dummies_v1", alias: "#{cluster.index_prefix}_dummies" } }]
        })
      }.not_to raise_error

      expect(cluster.api.aliases(index: "#{cluster.index_prefix}_dummies", name: '*')).to eq(
        "#{cluster.index_prefix}_dummies_v1" => { 'aliases' => { "#{cluster.index_prefix}_dummies" => {} } },
      )
    end
  end

  it 'replace an alias to an index' do
    es_client do |client, _conf, cluster|
      cluster.api.create_index(index: "#{cluster.index_prefix}_dummies_v1", body: {
        aliases: { "#{cluster.index_prefix}_dummies" => {} },
        settings: { number_of_shards: 1, number_of_replicas: 0 },
      })
      cluster.api.create_index(index: "#{cluster.index_prefix}_dummies_v2", body: {
        settings: { number_of_shards: 1, number_of_replicas: 0 },
      })

      expect {
        cluster.api.update_aliases(body: { actions: [
          { remove: { index: "#{cluster.index_prefix}_dummies_v1", alias: "#{cluster.index_prefix}_dummies" } },
          { add: { index: "#{cluster.index_prefix}_dummies_v2", alias: "#{cluster.index_prefix}_dummies" } },
        ] })
      }.not_to raise_error

      expect(cluster.api.aliases(index: "#{cluster.index_prefix}_dummies", name: '*')).to eq(
        "#{cluster.index_prefix}_dummies_v2" => { 'aliases' => { "#{cluster.index_prefix}_dummies" => {} } },
      )
    end
  end
end
