# frozen_string_literal: true

RSpec.shared_examples "index.refresh" do
  include_context 'with geos index definition'

  it "raises an Esse::Transport::ServerError exception when api throws an error" do
    es_client do |client, _conf, cluster|
      expect{
        GeosIndex.refresh(suffix: "2022")
      }.to raise_error(Esse::Transport::ServerError)
    end
  end

  it "refreshes the aliased index" do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: true, suffix: '2022')

      resp = nil
      expect {
        resp = GeosIndex.refresh
      }.not_to raise_error
      expect(resp).to be_a(Hash)
    end
  end

  it "refreshes the unaliased index" do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: false, suffix: "2022")

      resp = nil
      expect {
        resp = GeosIndex.refresh(suffix: "2022")
      }.not_to raise_error
      expect(resp).to be_a(Hash)
    end
  end
end
