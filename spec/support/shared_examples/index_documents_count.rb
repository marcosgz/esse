# frozen_string_literal: true

RSpec.shared_examples 'index.count' do |doc_type: false|
  include_context 'with venues index definition'

  let(:params) do
    doc_type ? { type: 'venue' } : {}
  end
  let(:index_suffix) { SecureRandom.hex(8) }

  it 'raises an Esse::Transport::ServerError exception when api throws an error' do
    es_client do |client, _conf, cluster|
      expect {
        VenuesIndex.count
      }.to raise_error(Esse::Transport::NotFoundError)
    end
  end

  it 'counts the documents in the aliased index' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: true, suffix: index_suffix)
      VenuesIndex.import(refresh: true, suffix: index_suffix, **params)

      resp = nil
      expect {
        resp = VenuesIndex.count
      }.not_to raise_error
      expect(resp).to eq(total_venues)
    end
  end

  it 'counts the documents in the unaliased index' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: false, suffix: index_suffix)
      VenuesIndex.import(refresh: true, suffix: index_suffix, **params)

      resp = nil
      expect {
        resp = VenuesIndex.count(suffix: index_suffix, **params)
      }.not_to raise_error
      expect(resp).to eq(total_venues)
    end
  end

  it 'counts using the q parameter' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: true, suffix: index_suffix)
      VenuesIndex.import(refresh: true, suffix: index_suffix, **params)

      resp = nil
      expect {
        resp = VenuesIndex.count(q: 'name:Hotel', **params)
      }.not_to raise_error
      expect(resp).to eq(1)
    end
  end
end
