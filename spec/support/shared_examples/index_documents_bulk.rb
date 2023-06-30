# frozen_string_literal: true

RSpec.shared_examples 'index.bulk' do
  include_context 'with geos index definition'

  let(:states) do
    states_batches.flatten.map do |state|
      state_serializer.new(state)
    end
  end

  it 'indexes a batch of documents to the aliased index' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: true)

      resp = nil
      expect {
        resp = GeosIndex.bulk(index: states)
      }.not_to raise_error
      # @TODO return another object with status for each bulk operation
      expect(resp).to be_an(Array).and all(be_a(Esse::Import::RequestBody))
      expect(resp[0].stats[:index]).to eq(states.size)
    end
  end

  it 'creates a batch of documents to the aliased index' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: true)

      resp = nil
      expect {
        resp = GeosIndex.bulk(create: states)
      }.not_to raise_error
      # @TODO return another object with status for each bulk operation
      expect(resp).to be_an(Array).and all(be_a(Esse::Import::RequestBody))
      expect(resp[0].stats[:create]).to eq(states.size)
    end
  end

  it 'deletes a batch of documents to the aliased index' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: true)
      GeosIndex.import(refresh: true)

      resp = nil
      expect {
        resp = GeosIndex.bulk(delete: states)
      }.not_to raise_error
      # @TODO return another object with status for each bulk operation
      expect(resp).to be_an(Array).and all(be_a(Esse::Import::RequestBody))
      expect(resp[0].stats[:delete]).to eq(states.size)
    end
  end
end
