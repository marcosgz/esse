# frozen_string_literal: true

RSpec.shared_examples 'index.count' do
  include_context 'with geos index definition'

  let(:index_suffix) { SecureRandom.hex(8) }

  it 'raises an Esse::Transport::ServerError exception when api throws an error' do
    es_client do |client, _conf, cluster|
      expect {
        GeosIndex.count(id: -1)
      }.to raise_error(Esse::Transport::NotFoundError)
    end
  end

  it 'counts the documents in the aliased index' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: true, suffix: index_suffix)
      GeosIndex.import(refresh: true, suffix: index_suffix)

      resp = nil
      expect {
        resp = GeosIndex.count
      }.not_to raise_error
      expect(resp).to eq(6)
    end
  end

  it 'counts the documents in the unaliased index' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: false, suffix: index_suffix)
      GeosIndex.import(refresh: true, suffix: index_suffix)

      resp = nil
      expect {
        resp = GeosIndex.count(suffix: index_suffix)
      }.not_to raise_error
      expect(resp).to eq(6)
    end
  end

  it 'counts using the q parameter' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: true, suffix: index_suffix)
      GeosIndex.import(refresh: true, suffix: index_suffix)

      resp = nil
      expect {
        resp = GeosIndex.count(q: 'name:IL')
      }.not_to raise_error
      expect(resp).to eq(1)
    end
  end
end
