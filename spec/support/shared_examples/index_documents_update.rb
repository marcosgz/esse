# frozen_string_literal: true

RSpec.shared_examples 'index.update' do
  include_context 'with geos index definition'

  let(:index_suffix) { SecureRandom.hex(8) }

  it 'raises an Esse::Transport::ServerError exception when api throws an error' do
    es_client do |client, _conf, cluster|
      expect {
        GeosIndex.update(id: -1, body: { doc: { name: 'foo' } })
      }.to raise_error(Esse::Transport::NotFoundError)
    end
  end

  it 'raises ArgumentError when the :id is not provided' do
    es_client do |client, _conf, cluster|
      expect {
        GeosIndex.update(body: { doc: { name: 'foo' } })
      }.to raise_error(ArgumentError, 'missing keyword: id')
    end
  end

  it 'raises ArgumentError when the :body is not provided' do
    es_client do |client, _conf, cluster|
      expect {
        GeosIndex.update(id: 1)
      }.to raise_error(ArgumentError, 'missing keyword: body')
    end
  end

  it 'updates the document in the aliased index' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: true, suffix: index_suffix)
      GeosIndex.import(refresh: true, suffix: index_suffix)

      resp = nil
      expect {
        resp = GeosIndex.update(id: 1, body: { doc: { name: 'New Name' } })
      }.not_to raise_error
      expect(resp['result']).to eq('updated')

      resp = GeosIndex.get(id: 1)
      expect(resp['_source']).to include('name' => 'New Name')
    end
  end

  it 'updates the document in the unaliased index' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: false, suffix: index_suffix)
      GeosIndex.import(refresh: true, suffix: index_suffix)

      resp = nil
      expect {
        resp = GeosIndex.update(id: 1, body: { doc: { name: 'New Name' } }, suffix: index_suffix)
      }.not_to raise_error
      expect(resp['result']).to eq('updated')

      resp = GeosIndex.get(id: 1, suffix: index_suffix)
      expect(resp['_source']).to include('name' => 'New Name')
    end
  end

  it 'updates the document using the instance of Esse::Serializer' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: true, suffix: index_suffix)
      GeosIndex.import(refresh: true)

      resp = nil
      expect {
        resp = GeosIndex.update(Esse::HashDocument.new(id: 1, name: 'New Name'))
      }.not_to raise_error
      expect(resp['result']).to eq('updated')

      resp = GeosIndex.get(id: 1)
      expect(resp['_source']).to include('name' => 'New Name')
    end
  end
end
