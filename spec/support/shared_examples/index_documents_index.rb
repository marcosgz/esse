# frozen_string_literal: true

RSpec.shared_examples 'index.index' do
  include_context 'with venues index definition'

  it 'raises ArgumentError when the :id is not provided' do
    es_client do |client, _conf, cluster|
      expect {
        VenuesIndex.index(body: { name: 'Restaurant' })
      }.to raise_error(ArgumentError, 'missing keyword: id')
    end
  end

  it 'raises ArgumentError when the :body is not provided' do
    es_client do |client, _conf, cluster|
      expect {
        VenuesIndex.index(id: 1)
      }.to raise_error(ArgumentError, 'missing keyword: body')
    end
  end

  it 'indexes a new document in the aliased index' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: true)

      resp = nil
      expect {
        resp = VenuesIndex.index(id: 1, body: { name: 'New Name' })
      }.not_to raise_error
      expect(resp['result']).to eq('created')

      resp = VenuesIndex.get(id: 1)
      expect(resp['_source']).to include('name' => 'New Name')
    end
  end

  it 'updates the document in the aliased index' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: true)
      VenuesIndex.import(refresh: true)

      resp = nil
      expect {
        resp = VenuesIndex.index(id: 1, body: { name: 'New Name' })
      }.not_to raise_error
      expect(resp['result']).to eq('updated')

      resp = VenuesIndex.get(id: 1)
      expect(resp['_source']).to include('name' => 'New Name')
    end
  end

  it 'indexes a new document in the unaliased index' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: false, suffix: '2022')

      resp = nil
      expect {
        resp = VenuesIndex.index(id: 1, body: { name: 'New Name' }, suffix: '2022')
      }.not_to raise_error
      expect(resp['result']).to eq('created')
      expect(resp['_index']).to eq("#{cluster.index_prefix}_venues_2022")

      resp = VenuesIndex.get(id: 1, suffix: '2022')
      expect(resp['_source']).to include('name' => 'New Name')
    end
  end

  it 'updates the document in the unaliased index' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: false, suffix: '2022')
      VenuesIndex.import(refresh: true, suffix: '2022')

      resp = nil
      expect {
        resp = VenuesIndex.index(id: 1, body: { name: 'New Name' }, suffix: '2022')
      }.not_to raise_error
      expect(resp['result']).to eq('updated')
      expect(resp['_index']).to eq("#{cluster.index_prefix}_venues_2022")

      resp = VenuesIndex.get(id: 1, suffix: '2022')
      expect(resp['_source']).to include('name' => 'New Name')
    end
  end

  it 'indexes the document using the instance of Esse::Serializer' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: true)

      resp = nil
      expect {
        resp = VenuesIndex.index(Esse::HashDocument.new(id: 1, name: 'New Name'))
      }.not_to raise_error
      expect(resp['result']).to eq('created')

      resp = VenuesIndex.get(id: 1)
      expect(resp['_source']).to include('name' => 'New Name')
    end
  end
end
