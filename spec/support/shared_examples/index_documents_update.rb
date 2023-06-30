# frozen_string_literal: true

RSpec.shared_examples 'index.update' do |doc_type: false|
  include_context 'with venues index definition'

  let(:params) do
    doc_type ? { type: 'venue' } : {}
  end
  let(:doc_params) do
    doc_type ? { _type: 'venue' } : {}
  end
  let(:index_suffix) { SecureRandom.hex(8) }

  it 'raises an Esse::Transport::ServerError exception when api throws an error' do
    es_client do |client, _conf, cluster|
      expect {
        VenuesIndex.update(id: -1, body: { doc: { name: 'foo' } }, **params)
      }.to raise_error(Esse::Transport::NotFoundError)
    end
  end

  it 'raises ArgumentError when the :id is not provided' do
    es_client do |client, _conf, cluster|
      expect {
        VenuesIndex.update(body: { doc: { name: 'foo' } }, **params)
      }.to raise_error(ArgumentError, 'missing keyword: id')
    end
  end

  it 'raises ArgumentError when the :body is not provided' do
    es_client do |client, _conf, cluster|
      expect {
        VenuesIndex.update(id: 1, **params)
      }.to raise_error(ArgumentError, 'missing keyword: body')
    end
  end

  it 'updates the document in the aliased index' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: true, suffix: index_suffix)
      VenuesIndex.import(refresh: true, suffix: index_suffix, **params)

      resp = nil
      expect {
        resp = VenuesIndex.update(id: 1, body: { doc: { name: 'New Name' } }, **params)
      }.not_to raise_error
      expect(resp['result']).to eq('updated')

      resp = VenuesIndex.get(id: 1)
      expect(resp['_source']).to include('name' => 'New Name')
    end
  end

  it 'updates the document in the unaliased index' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: false, suffix: index_suffix)
      VenuesIndex.import(refresh: true, suffix: index_suffix, **params)

      resp = nil
      expect {
        resp = VenuesIndex.update(id: 1, body: { doc: { name: 'New Name' } }, suffix: index_suffix, **params)
      }.not_to raise_error
      expect(resp['result']).to eq('updated')

      resp = VenuesIndex.get(id: 1, suffix: index_suffix)
      expect(resp['_source']).to include('name' => 'New Name')
    end
  end

  it 'updates the document using the instance of Esse::Serializer' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: true)
      VenuesIndex.import(refresh: true, **params)

      document = Esse::HashDocument.new(id: 1, name: 'New Name', **doc_params)
      resp = nil
      expect {
        resp = VenuesIndex.update(document)
      }.not_to raise_error
      expect(resp['result']).to eq('updated')

      resp = VenuesIndex.get(id: 1)
      expect(resp['_source']).to include('name' => 'New Name')
    end
  end
end
