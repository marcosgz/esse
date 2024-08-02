# frozen_string_literal: true

RSpec.shared_examples 'index.update_by_query' do |doc_type: false|
  include_context 'with venues index definition'

  let(:params) do
    doc_type ? { type: 'venue' } : {}
  end
  let(:doc_params) do
    doc_type ? { _type: 'venue' } : {}
  end
  let(:index_suffix) { SecureRandom.hex(8) }
  let(:body) { { script: { source: 'ctx._source.title = "foo"' }, query: { match_all: {} } } }

  it 'raises an Esse::Transport::ReadonlyClusterError exception when the cluster is readonly' do
    es_client do |client, _conf, cluster|
      cluster.warm_up!
      expect(client).not_to receive(:perform_request)
      cluster.readonly = true
      expect {
        VenuesIndex.update_by_query(body: body, **params)
      }.to raise_error(Esse::Transport::ReadonlyClusterError)
    end
  end

  it 'raises an Esse::Transport::ServerError exception when api throws an error' do
    es_client do |client, _conf, cluster|
      expect {
        VenuesIndex.update_by_query(body: body, **params)
      }.to raise_error(Esse::Transport::NotFoundError)
    end
  end

  it 'updates the documents in the aliased index' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: true, suffix: index_suffix)
      VenuesIndex.import(refresh: true, suffix: index_suffix, **params)

      resp = nil
      expect {
        resp = VenuesIndex.update_by_query(body: body, **params)
      }.not_to raise_error
      expect(resp['total']).to eq(total_venues)
      expect(resp['updated']).to eq(total_venues)
    end
  end

  it 'updates the documents in the unaliased index' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: false, suffix: index_suffix)
      VenuesIndex.import(refresh: true, suffix: index_suffix, **params)

      resp = nil
      expect {
        resp = VenuesIndex.update_by_query(body: body, suffix: index_suffix, **params)
      }.not_to raise_error
      expect(resp['total']).to eq(total_venues)
      expect(resp['updated']).to eq(total_venues)
    end
  end
end
