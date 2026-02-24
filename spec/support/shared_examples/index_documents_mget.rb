# frozen_string_literal: true

RSpec.shared_examples 'index.mget' do
  include_context 'with venues index definition'

  it 'raises ArgumentError when :ids is not provided' do
    es_client do |_client, _conf, _cluster|
      expect {
        VenuesIndex.mget
      }.to raise_error(ArgumentError)
    end
  end

  it 'returns documents using raw IDs' do
    es_client do |_client, _conf, _cluster|
      VenuesIndex.create_index
      VenuesIndex.import(refresh: true)

      resp = nil
      expect {
        resp = VenuesIndex.mget(ids: [1, 2])
      }.not_to raise_error
      expect(resp['docs'].size).to eq(2)
      expect(resp['docs'].map { |d| d['_id'] }).to match_array(%w[1 2])
      expect(resp['docs'].all? { |d| d['found'] }).to eq(true)
    end
  end

  it 'returns documents using Esse::Document instances' do
    es_client do |_client, _conf, _cluster|
      VenuesIndex.create_index
      VenuesIndex.import(refresh: true)

      resp = nil
      expect {
        resp = VenuesIndex.mget(ids: [Esse::HashDocument.new(id: 1)])
      }.not_to raise_error
      expect(resp['docs'].size).to eq(1)
      expect(resp['docs'].first['_id']).to eq('1')
      expect(resp['docs'].first['found']).to eq(true)
    end
  end

  it 'returns documents using hash entries' do
    es_client do |_client, _conf, _cluster|
      VenuesIndex.create_index
      VenuesIndex.import(refresh: true)

      resp = nil
      expect {
        resp = VenuesIndex.mget(ids: [{ _id: 1 }, { _id: 2 }])
      }.not_to raise_error
      expect(resp['docs'].size).to eq(2)
      expect(resp['docs'].map { |d| d['_id'] }).to match_array(%w[1 2])
    end
  end

  it 'supports :suffix option' do
    es_client do |_client, _conf, _cluster|
      VenuesIndex.create_index
      VenuesIndex.import(refresh: true, suffix: 'v2')

      resp = nil
      expect {
        resp = VenuesIndex.mget(ids: [1], suffix: 'v2')
      }.not_to raise_error
      expect(resp['docs'].size).to eq(1)
      expect(resp['docs'].first['found']).to eq(true)
    end
  end

  it 'does not raise Esse::Transport::ReadonlyClusterError error when the cluster is readonly' do
    es_client do |_client, _conf, cluster|
      VenuesIndex.create_index
      VenuesIndex.import(refresh: true)

      cluster.readonly = true
      expect {
        VenuesIndex.mget(ids: [1])
      }.not_to raise_error
    end
  end
end
