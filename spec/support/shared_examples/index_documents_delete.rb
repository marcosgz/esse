# frozen_string_literal: true

RSpec.shared_examples 'index.delete' do
  include_context 'with geos index definition'

  let(:index_suffix) { SecureRandom.hex(8) }

  it 'raises an Esse::Transport::ServerError exception when api throws an error' do
    es_client do |client, _conf, cluster|
      expect {
        GeosIndex.delete(id: -1)
      }.to raise_error(Esse::Transport::NotFoundError)
    end
  end

  it 'raises ArgumentError when the :id is not provided' do
    es_client do |client, _conf, cluster|
      expect {
        GeosIndex.delete
      }.to raise_error(ArgumentError, 'missing keyword: id')
    end
  end

  it 'raises ArgumentError when the :id is nil' do
    es_client do |client, _conf, cluster|
      expect {
        GeosIndex.delete(id: nil)
      }.to raise_error(ArgumentError, "Required argument 'id' missing")
    end
  end

  it 'deletes the document from the aliased index' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: true, suffix: index_suffix)
      GeosIndex.import(refresh: true, suffix: index_suffix)

      resp = nil
      expect {
        resp = GeosIndex.delete(id: 1)
      }.not_to raise_error
      expect(resp['result']).to eq('deleted')
    end
  end

  it 'deletes the document from the unaliased index' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: false, suffix: index_suffix)
      GeosIndex.import(refresh: true, suffix: index_suffix)

      resp = nil
      expect {
        resp = GeosIndex.delete(id: 1, suffix: index_suffix)
      }.not_to raise_error
      expect(resp['result']).to eq('deleted')
    end
  end

  it 'deletes the document using the instance of Esse::Serializer' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: true, suffix: index_suffix)
      GeosIndex.import(refresh: true, suffix: index_suffix)

      resp = nil
      expect {
        resp = GeosIndex.delete(Esse::HashDocument.new(id: 1))
      }.not_to raise_error
      expect(resp['result']).to eq('deleted')
    end
  end
end
