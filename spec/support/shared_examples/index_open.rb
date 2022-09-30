# frozen_string_literal: true

RSpec.shared_examples "index.open" do
  include_context 'with geos index definition'

  it "raises an Esse::Transport::ServerError exception when api throws an error" do
    es_client do |client, _conf, cluster|
      expect{
        GeosIndex.open(suffix: "2022")
      }.to raise_error(Esse::Transport::ServerError)
    end
  end

  it "opens the aliased index" do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: true, suffix: '2022')
      GeosIndex.close(suffix: '2022')

      resp = nil
      expect {
        resp = GeosIndex.open
      }.not_to raise_error
      expect(resp['acknowledged']).to eq(true)
    end
  end

  it "opens the unaliased index" do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: false, suffix: "2022")
      GeosIndex.close(suffix: "2022")

      resp = nil
      expect {
        resp = GeosIndex.open(suffix: "2022")
      }.not_to raise_error
      expect(resp['acknowledged']).to eq(true)
    end
  end
end
