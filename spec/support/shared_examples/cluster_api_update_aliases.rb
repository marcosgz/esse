# frozen_string_literal: true

RSpec.shared_examples "cluster_api#update_aliases" do
  include_context 'with geos index definition' # @TODO Don't use Index stuff on Cluster API

  it "raises an Esse::Transport::ServerError exception when api throws an error" do
    es_client do |client, _conf, cluster|
      expect{
        cluster.api.update_aliases(body: { actions: [{ add: { index: "esse_unknow_index_name_v1", alias: "esse_unknow_index_name" } }] })
      }.to raise_error(Esse::Transport::ServerError)
    end
  end

  it "adds an alias to an index" do
    es_client do |client, _conf, cluster|
      GeosIndex.elasticsearch.create_index!(alias: false, suffix: "2022") # @TODO Don't use Index stuff on Cluster API

      expect {
        cluster.api.update_aliases(body: { actions: [{ add: { index: "#{GeosIndex.index_name}_2022", alias: GeosIndex.index_name } }] })
      }.not_to raise_error

      expect(cluster.api.aliases(index: GeosIndex.index_name, name: '*')).to eq(
        "#{GeosIndex.index_name}_2022" => { 'aliases' => { GeosIndex.index_name => {} } },
      )
    end
  end

  it "replace an alias to an index" do
    es_client do |client, _conf, cluster|
      GeosIndex.elasticsearch.create_index!(alias: true, suffix: "2021") # @TODO Don't use Index stuff on Cluster API
      GeosIndex.elasticsearch.create_index!(alias: false, suffix: "2022")

      expect {
        cluster.api.update_aliases(body: { actions: [
          { remove: { index: "#{GeosIndex.index_name}_2021", alias: GeosIndex.index_name } },
          { add: { index: "#{GeosIndex.index_name}_2022", alias: GeosIndex.index_name } },
        ] })
      }.not_to raise_error

      expect(cluster.api.aliases(index: GeosIndex.index_name, name: '*')).to eq(
        "#{GeosIndex.index_name}_2022" => { 'aliases' => { GeosIndex.index_name => {} } },
      )
    end
  end
end
