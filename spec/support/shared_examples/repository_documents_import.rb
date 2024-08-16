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

  context 'when the update_lazy_attributes is set' do
    it 'indexes the data and bulk updates all the lazy document attributes' do
      es_client do |client, _conf, cluster|
        GeosIndex.create_index(alias: true)

        resp = nil
        expect {
          resp = GeosIndex::County.import(update_lazy_attributes: true)
        }.not_to raise_error
        expect(resp).to eq(total_counties)

        GeosIndex.refresh
        expect(GeosIndex.count).to eq(total_counties)

        doc = GeosIndex.get(id: '888')
        expect(doc.dig('_source', 'country')).to eq('US')
        expect(doc.dig('_source', 'cities')).to eq([])
      end
    end

    it 'indexes the data and bulk updates given lazy document attribute' do
      es_client do |client, _conf, cluster|
        GeosIndex.create_index(alias: true)

        resp = nil
        expect {
          resp = GeosIndex::County.import(update_lazy_attributes: %i[country])
        }.not_to raise_error
        expect(resp).to eq(total_counties)

        GeosIndex.refresh
        expect(GeosIndex.count).to eq(total_counties)

        doc = GeosIndex.get(id: '888')
        expect(doc.dig('_source', 'country')).to eq('US')
        expect(doc.dig('_source', 'cities')).to eq(nil)
      end
    end
  end

  context 'when the eager_load_lazy_attributes is set' do
    it 'indexes the data and bulk updates all the eager document attributes' do
      es_client do |client, _conf, cluster|
        GeosIndex.create_index(alias: true)

        resp = nil
        expect {
          resp = GeosIndex::County.import(eager_load_lazy_attributes: true)
        }.not_to raise_error
        expect(resp).to eq(total_counties)

        GeosIndex.refresh
        expect(GeosIndex.count).to eq(total_counties)

        doc = GeosIndex.get(id: '888')
        expect(doc.dig('_source', 'country')).to eq('US')
        expect(doc.dig('_source', 'cities')).to eq([])
      end
    end

    it 'indexes the data and bulk updates given eager document attribute' do
      es_client do |client, _conf, cluster|
        GeosIndex.create_index(alias: true)

        resp = nil
        expect {
          resp = GeosIndex::County.import(eager_load_lazy_attributes: %i[country])
        }.not_to raise_error
        expect(resp).to eq(total_counties)

        GeosIndex.refresh
        expect(GeosIndex.count).to eq(total_counties)

        doc = GeosIndex.get(id: '888')
        expect(doc.dig('_source', 'country')).to eq('US')
        expect(doc.dig('_source', 'cities')).to eq(nil)
      end
    end
  end

  context 'when the preload_lazy_attributes is set' do
    it 'search the given lazy document attributes before the bulk import' do
      es_client do |client, _conf, cluster|
        GeosIndex.create_index(alias: true)

        doc_to_import = GeosIndex::County.documents(conditions: ->(h) { h[:id] == 888 }).first
        doc_to_import.mutate(:country) { 'BR' }
        GeosIndex.index(doc_to_import, refresh: :wait_for)

        resp = nil
        expect {
          resp = GeosIndex::County.import(preload_lazy_attributes: %i[country])
        }.not_to raise_error
        expect(resp).to eq(total_counties)

        GeosIndex.refresh
        expect(GeosIndex.count).to eq(total_counties)

        doc = GeosIndex.get(id: '888')
        expect(doc.dig('_source', 'country')).to eq('BR')

        doc = GeosIndex.get(id: '999')
        expect(doc.dig('_source', 'country')).to eq(nil)
      end
    end
  end

  context 'when the both preload_lazy_attributes and update_lazy_attributes are set' do
    it 'search the given lazy document attributes before the bulk import, and do an additional bulk update for the not preloaded attributes' do
      es_client do |client, _conf, cluster|
        GeosIndex.create_index(alias: true)

        doc_to_import = GeosIndex::County.documents(conditions: ->(h) { h[:id] == 888 }).first
        doc_to_import.mutate(:country) { 'BR' }
        GeosIndex.index(doc_to_import, refresh: :wait_for)

        resp = nil
        expect {
          resp = GeosIndex::County.import(preload_lazy_attributes: %i[country], update_lazy_attributes: %i[country])
        }.not_to raise_error
        expect(resp).to eq(total_counties)

        GeosIndex.refresh
        expect(GeosIndex.count).to eq(total_counties)

        doc = GeosIndex.get(id: '888')
        expect(doc.dig('_source', 'country')).to eq('BR')

        doc = GeosIndex.get(id: '999')
        expect(doc.dig('_source', 'country')).to eq('US')
      end
    end
  end

  context 'when the document routing is set' do
    include_context 'with stories index definition'

    it 'indexes the data and bulk updates all the document routing' do |example|
      es_client do |client, _conf, cluster|
        StoriesIndex.create_index(alias: true)

        resp = nil
        expect {
          resp = StoriesIndex::Story.import
        }.not_to raise_error
        expect(resp).to eq(stories.size)

        StoriesIndex.refresh
        expect(StoriesIndex.count).to eq(stories.size)

        doc = StoriesIndex.get(id: '1001', routing: 'nyt')
        expect(doc.dig('_source', 'publication')).to eq('nyt')
        expect(doc.dig('_source', 'tags')).to be(nil)
        unless %w[1.x].include?(example.metadata[:es_version])
          expect(doc.dig('_routing')).to eq('nyt')
        end
      end
    end

    it 'lazy update the document tags attribute' do
      es_client do |client, _conf, cluster|
        StoriesIndex.create_index(alias: true)

        resp = nil
        expect {
          resp = StoriesIndex::Story.import(update_lazy_attributes: %i[tags])
        }.not_to raise_error
        expect(resp).to eq(stories.size)

        StoriesIndex.refresh
        expect(StoriesIndex.count).to eq(stories.size)

        doc = StoriesIndex.get(id: '1001', routing: 'nyt')
        expect(doc.dig('_source', 'tags')).to eq(%w[news politics])
      end
    end
  end
end
