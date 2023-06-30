# frozen_string_literal: true

RSpec.shared_examples 'index.import' do
  include_context 'with venues index definition'

  it 'loads the data from repository and indexes to the aliased index' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: true)

      resp = nil
      expect {
        resp = VenuesIndex.import
      }.not_to raise_error
      expect(resp).to eq(total_venues)

      VenuesIndex.refresh
      expect(VenuesIndex.count).to eq(total_venues)
    end
  end

  it 'automatically refreshes the index after import' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: true)

      resp = nil
      expect {
        resp = VenuesIndex.import(refresh: true)
      }.not_to raise_error
      expect(resp).to eq(total_venues)

      expect(VenuesIndex.count).to eq(total_venues)
    end
  end

  it 'loads the data from repository and indexes to the unaliased index' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: false, suffix: '2022')

      resp = nil
      expect {
        resp = VenuesIndex.import(suffix: '2022')
      }.not_to raise_error
      expect(resp).to eq(total_venues)

      VenuesIndex.refresh(suffix: '2022')
      expect(VenuesIndex.count(suffix: '2022')).to eq(total_venues)
    end
  end

  it 'imports the data from repository applying the given context' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: true)

      resp = nil
      expect {
        resp = VenuesIndex.import(context: { conditions: ->(entry) { entry.id <= 3 } })
      }.not_to raise_error
      expect(resp).to eq(3)

      VenuesIndex.refresh
      expect(VenuesIndex.count).to eq(3)
    end
  end
end
