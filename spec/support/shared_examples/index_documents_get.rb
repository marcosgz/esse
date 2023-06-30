# frozen_string_literal: true

RSpec.shared_examples 'index.get' do
  include_context 'with venues index definition'

  it 'raises an Esse::Transport::ServerError exception when api throws an error' do
    es_client do |client, _conf, cluster|
      expect {
        VenuesIndex.get(id: -1)
      }.to raise_error(Esse::Transport::NotFoundError)
    end
  end

  it 'raises ArgumentError when the :id is not provided' do
    es_client do |client, _conf, cluster|
      expect {
        VenuesIndex.get
      }.to raise_error(ArgumentError, 'missing keyword: id')
    end
  end

  it 'returns the document using :id' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index
      VenuesIndex.import(refresh: true)

      doc = nil
      expect {
        doc = VenuesIndex.get(id: 1)
      }.not_to raise_error
      expect(doc['_id']).to eq('1')
      expect(doc['_source']).to eq('name' => 'Gourmet Paradise')
    end
  end

  it 'returns the document using :id and :suffix' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index
      VenuesIndex.import(refresh: true, suffix: 'v2')

      doc = nil
      expect {
        doc = VenuesIndex.get(id: 1, suffix: 'v2')
      }.not_to raise_error
      expect(doc['_id']).to eq('1')
      expect(doc['_source']).to eq('name' => 'Gourmet Paradise')

      expect {
        VenuesIndex.get(id: 1, suffix: 'v1')
      }.to raise_error(Esse::Transport::NotFoundError)
    end
  end

  it 'returns the document the instance of Esse::Serializer' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index
      VenuesIndex.import(refresh: true)

      doc = nil
      expect {
        doc = VenuesIndex.get(Esse::HashDocument.new(id: 1))
      }.not_to raise_error
      expect(doc['_id']).to eq('1')
      expect(doc['_source']).to eq('name' => 'Gourmet Paradise')
    end
  end

  it 'returns the document the instance of Esse::Serializer with routing' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index
      VenuesIndex.import(refresh: true, routing: 'geo')

      doc = nil
      expect {
        doc = VenuesIndex.get(Esse::HashDocument.new(id: 1, routing: 'geo'))
      }.not_to raise_error
      expect(doc['_id']).to eq('1')
      expect(doc['_source']).to eq('name' => 'Gourmet Paradise')
    end
  end
end
