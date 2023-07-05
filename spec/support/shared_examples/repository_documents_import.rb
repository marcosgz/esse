# frozen_string_literal: true

RSpec.shared_examples 'repository.import' do
  include_context 'with geos index definition'

  it 'loads the data from repository and indexes to the aliased index' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: true)

      resp = nil
      expect {
        resp = GeosIndex::County.import
      }.not_to raise_error
      expect(resp).to eq(total_counties)

      GeosIndex.refresh
      expect(GeosIndex.count).to eq(total_counties)
    end
  end

  it 'automatically refreshes the index after import' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: true)

      resp = nil
      expect {
        resp = GeosIndex::County.import(refresh: true)
      }.not_to raise_error
      expect(resp).to eq(total_counties)

      expect(GeosIndex.count).to eq(total_counties)
    end
  end

  it 'loads the data from repository and indexes to the unaliased index' do
    index_suffix = SecureRandom.hex(4)
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: false, suffix: index_suffix)

      resp = nil
      expect {
        resp = GeosIndex::County.import(suffix: index_suffix)
      }.not_to raise_error
      expect(resp).to eq(total_counties)

      GeosIndex.refresh(suffix: index_suffix)
      expect(GeosIndex.count(suffix: index_suffix)).to eq(total_counties)
    end
  end

  it 'imports the data from repository applying the given context' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: true)

      resp = nil
      expect {
        resp = GeosIndex::County.import(context: { conditions: ->(entry) { entry.id <= 888 } })
      }.not_to raise_error
      expect(resp).to eq(2)

      GeosIndex.refresh
      expect(GeosIndex.count).to eq(2)
    end
  end
end
