# frozen_string_literal: true

RSpec.shared_examples "cluster_api#aliases" do
  it 'retrieves the aliases for the given index' do
    es_client do |client, _conf, cluster|
      GeosIndex.elasticsearch.create_index!(alias: true, suffix: "2022")

      expect(cluster.api.aliases(index: GeosIndex.index_name, name: '*')).to eq(
        "#{GeosIndex.index_name}_2022" => { 'aliases' => { GeosIndex.index_name => {} } },
      )
    end
  end

  it 'raises an exeption when api throws an error' do
    es_client do |client, _conf, cluster|
      expect{
        cluster.api.aliases(name: 'esse_unknow_index_name')
      }.to raise_error(Esse::Transport::NotFoundError)
    end
  end
end
