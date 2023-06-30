# frozen_string_literal: true

RSpec.shared_examples 'index.import' do
  include_context 'with geos index definition'

  it 'loads the data from repository and indexes to the aliased index' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: true)

      resp = nil
      expect {
        resp = GeosIndex.import
      }.not_to raise_error
      expect(resp).to eq(total_geos)

      GeosIndex.refresh
      expect(GeosIndex.count).to eq(total_geos)
    end
  end

  it 'automatically refreshes the index after import' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: true)

      resp = nil
      expect {
        resp = GeosIndex.import(refresh: true)
      }.not_to raise_error
      expect(resp).to eq(total_geos)

      expect(GeosIndex.count).to eq(total_geos)
    end
  end

  it 'loads the data from repository and indexes to the unaliased index' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: false, suffix: '2022')

      resp = nil
      expect {
        resp = GeosIndex.import(suffix: '2022')
      }.not_to raise_error
      expect(resp).to eq(total_geos)

      GeosIndex.refresh(suffix: '2022')
      expect(GeosIndex.count(suffix: '2022')).to eq(total_geos)
    end
  end

  it 'imports the data from repository applying the given context' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: true)

      resp = nil
      expect {
        resp = GeosIndex.import(context: { conditions: ->(entry) { entry.id <= 3 } })
      }.not_to raise_error
      expect(resp).to eq(3)

      GeosIndex.refresh
      expect(GeosIndex.count).to eq(3)
    end
  end
end
