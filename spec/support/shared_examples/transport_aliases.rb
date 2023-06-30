# frozen_string_literal: true

RSpec.shared_examples 'transport#aliases' do
  it 'retrieves the aliases for the given index' do
    es_client do |client, _conf, cluster|
      cluster.api.create_index(index: "#{cluster.index_prefix}_dummies_v1", body: {
        aliases: { "#{cluster.index_prefix}_dummies" => {} },
        settings: { number_of_shards: 1, number_of_replicas: 0 },
      })

      expect(cluster.api.aliases(index: "#{cluster.index_prefix}_dummies", name: '*')).to eq(
        "#{cluster.index_prefix}_dummies_v1" => { 'aliases' => { "#{cluster.index_prefix}_dummies" => {} } },
      )
    end
  end

  it 'raises an exeption when api throws an error' do
    es_client do |client, _conf, cluster|
      expect {
        cluster.api.aliases(name: 'esse_unknow_index_name')
      }.to raise_error(Esse::Transport::NotFoundError)
    end
  end
end
