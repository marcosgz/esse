# frozen_string_literal: true

RSpec.shared_examples "index.delete_index" do
  include_context 'with geos index definition'

  it "raises an Esse::Transport::ServerError exception when api throws an error" do
    es_client do |client, _conf, cluster|
      expect{
        GeosIndex.delete_index(suffix: "v1")
      }.to raise_error(Esse::Transport::ServerError)
    end
  end

  it "deletes the aliased index" do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: true, suffix: 'v1')

      resp = nil
      expect {
        resp = GeosIndex.delete_index
      }.not_to raise_error
      expect(resp['acknowledged']).to eq(true)
      expect(cluster.api.index_exist?(index: GeosIndex.index_name(suffix: 'v1'))).to eq(false)
    end
  end

  it "deletes the unaliased index" do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: false, suffix: "v1")

      resp = nil
      expect {
        resp = GeosIndex.delete_index(suffix: "v1")
      }.not_to raise_error
      expect(resp['acknowledged']).to eq(true)
      expect(cluster.api.index_exist?(index: GeosIndex.index_name(suffix: 'v1'))).to eq(false)

    end
  end

  it "deletes the index created with root naming" do
    es_client do |client, _conf, cluster|
      cluster.api.create_index(index: GeosIndex.index_name, body: {
        settings: { number_of_shards: 1, number_of_replicas: 0 },
      })

      resp = nil
      expect {
        resp = GeosIndex.delete_index
      }.not_to raise_error
      expect(resp['acknowledged']).to eq(true)
      expect(cluster.api.index_exist?(index: GeosIndex.index_name)).to eq(false)
    end
  end
end
