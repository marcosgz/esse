# frozen_string_literal: true

RSpec.shared_examples "index.create_index" do
  include_context 'with geos index definition'

  it 'creates a suffixed index and adds the alias' do
    es_client do |client, _conf, cluster|
      expect {
        GeosIndex.create_index(suffix: "2022")
      }.to change { GeosIndex.indices_pointing_to_alias }.from([]).to(["#{GeosIndex.index_name}_2022"])
    end
  end

  it 'creates a index but not the alias' do
    es_client do |client, _conf, cluster|
      expect {
        GeosIndex.create_index(suffix: "2022", alias: false)
      }.not_to change { GeosIndex.indices_pointing_to_alias }
      expect(cluster.client.indices.exists(index: "#{GeosIndex.index_name}_2022")).to be(true)
    end
  end

  it 'uses the default suffix when not provided' do
    es_client do |client, _conf, cluster|
      expect(Esse).to receive(:timestamp).and_return("20220101")
      expect {
        GeosIndex.create_index
      }.to change { GeosIndex.indices_pointing_to_alias }.from([]).to(["#{GeosIndex.index_name}_20220101"])
    end
  end

  it 'uses the index_version suffix when defined' do
    es_client do |client, _conf, cluster|
      GeosIndex.index_version = "v2"
      expect {
        GeosIndex.create_index
      }.to change { GeosIndex.indices_pointing_to_alias }.from([]).to(["#{GeosIndex.index_name}_v2"])
    end
  end

  it 'uses the settings_hash and settings_hash as default definition' do
    es_client do |client, _conf, cluster|
      expect(GeosIndex).to receive(:settings_hash).and_return({ settings: { number_of_shards: 1 } })
      expect(GeosIndex).to receive(:mappings_hash).and_return({ mappings: { } })
      allow(Esse).to receive(:timestamp).and_return("20220101")

      api = cluster.api
      allow(cluster).to receive(:api).and_return(api)
      expect(api).to receive(:create_index).with(
        index: GeosIndex.index_name(suffix: '20220101'),
        body: { aliases: { GeosIndex.index_name => {} }, settings: { number_of_shards: 1 }, mappings: { } },
      ).and_call_original

      expect {
        GeosIndex.create_index
      }.to change { GeosIndex.indices_pointing_to_alias }.from([]).to([GeosIndex.index_name(suffix: '20220101')])
    end
  end

  it 'raises an Esse::Transport::BadRequestError exception when api throws an error' do
    es_client do |client, _conf, cluster|
      cluster.api.create_index(index: GeosIndex.index_name(suffix: 'v1'))
      expect{
        GeosIndex.create_index(suffix: "v1")
      }.to raise_error(Esse::Transport::BadRequestError).with_message(/already.exists/)
    end
  end
end
