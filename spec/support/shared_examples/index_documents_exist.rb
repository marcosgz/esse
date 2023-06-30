# frozen_string_literal: true

RSpec.shared_examples 'index.exist?' do
  include_context 'with geos index definition'

  it 'returns false when the index does not exist' do
    es_client do |client, _conf, cluster|
      resp = nil
      expect {
        resp = GeosIndex.exist?(id: -1)
      }.not_to raise_error
      expect(resp).to eq(false)
    end
  end

  it 'raises ArgumentError when the :id is not provided' do
    es_client do |client, _conf, cluster|
      expect {
        GeosIndex.exist?
      }.to raise_error(ArgumentError, 'missing keyword: id')
    end
  end

  it 'checks the document existence using :id' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index
      GeosIndex.import(refresh: true)

      resp = nil
      expect {
        resp = GeosIndex.exist?(id: 1)
      }.not_to raise_error
      expect(resp).to eq(true)

      expect {
        resp = GeosIndex.exist?(id: -1)
      }.not_to raise_error
      expect(resp).to eq(false)
    end
  end

  it 'checks the document existence using :id and :suffix' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index
      GeosIndex.import(refresh: true, suffix: 'v2')

      resp = nil
      expect {
        resp = GeosIndex.exist?(id: 1, suffix: 'v2')
      }.not_to raise_error
      expect(resp).to eq(true)

      expect {
        resp = GeosIndex.exist?(id: 1, suffix: 'v1')
      }.not_to raise_error
      expect(resp).to eq(false)
    end
  end

  it 'checks the document existence using the instance of Esse::Serializer' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index
      GeosIndex.import(refresh: true)

      resp = nil
      expect {
        resp = GeosIndex.exist?(Esse::HashDocument.new(id: 1))
      }.not_to raise_error
      expect(resp).to eq(true)

      expect {
        resp = GeosIndex.exist?(Esse::HashDocument.new(id: -1))
      }.not_to raise_error
      expect(resp).to eq(false)
    end
  end
end
