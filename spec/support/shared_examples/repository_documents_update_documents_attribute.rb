# frozen_string_literal: true

# rubocop:disable RSpec/MultipleExpectations
RSpec.shared_examples 'repository.update_documents_attribute' do
  context 'when the index has routing' do
    include_context 'with stories index definition'

    it 'adds the :tags from lazy_document_attribute to the document' do
      es_client do |client, _conf, cluster|
        StoriesIndex.create_index(alias: true)

        resp = nil
        expect {
          resp = StoriesIndex::Story.import(context: { conditions: ->(s) { s[:publication] == 'nyt' } })
        }.not_to raise_error
        expect(resp).to eq(nyt_stories.size)

        StoriesIndex.refresh
        expect(StoriesIndex.count).to eq(nyt_stories.size)

        doc = StoriesIndex.get(id: '1001', routing: 'nyt')
        expect(doc.dig('_source', 'publication')).to eq('nyt')
        expect(doc.dig('_source', 'tags')).to be(nil)

        expect {
          resp = StoriesIndex::Story.update_documents_attribute(:tags, { _id: '1001', routing: 'nyt' }, refresh: true)
        }.not_to raise_error

        doc = StoriesIndex.get(id: '1001', routing: 'nyt')
        expect(doc.dig('_source', 'publication')).to eq('nyt')
        expect(doc.dig('_source', 'tags')).to eq(%w[news politics])
      end
    end
  end

  context 'when document does not exist' do
    include_context 'with stories index definition'

    it 'raises the Esse::Transport::BulkResponseError error when passing index_on_missing: false' do
      es_client do |client, _conf, cluster|
        StoriesIndex.create_index(alias: true)

        expect {
          StoriesIndex::Story.update_documents_attribute(:tags, [
            { _id: '1001', routing: 'nyt' },
          ], index_on_missing: false)
        }.to raise_error(Esse::Transport::BulkResponseError)
      end
    end

    it 'retries importing the document when passing index_on_missing: true' do
      es_client do |client, _conf, cluster|
        StoriesIndex.create_index(alias: true)

        resp = nil
        expect {
          resp = StoriesIndex::Story.import(context: { conditions: ->(s) { s[:id] == 1_001 } })
        }.not_to raise_error

        StoriesIndex.refresh
        expect(StoriesIndex.count).to eq(1)

        expect {
          resp = StoriesIndex::Story.update_documents_attribute(:tags, [
            { _id: '1002', routing: 'nyt' },
            { _id: '1003', routing: 'nyt' }
          ], refresh: true)
        }.not_to raise_error(Esse::Transport::BulkResponseError)

        StoriesIndex.refresh
        expect(StoriesIndex.count).to eq(nyt_stories.size)

        doc = StoriesIndex.get(id: '1002', routing: 'nyt')
        expect(doc.dig('_source', 'publication')).to eq('nyt')
      end
    end
  end

  context 'when the index does not have routing' do
    include_context 'with geos index definition'

    it 'adds the :location from lazy_document_attribute to the document' do
      es_client do |client, _conf, cluster|
        GeosIndex.create_index

        resp = nil
        expect {
          resp = GeosIndex::County.import
        }.not_to raise_error
        expect(resp).to eq(total_counties)

        GeosIndex.refresh
        expect(GeosIndex.count).to eq(total_counties)

        doc = GeosIndex.get(id: '999')
        expect(doc.dig('_source', 'country')).to be(nil)

        expect {
          resp = GeosIndex::County.update_documents_attribute(:country, '999', refresh: true)
        }.not_to raise_error

        doc = GeosIndex.get(id: '999')
        expect(doc.dig('_source', 'country')).to eq('US')
      end
    end
  end
end
