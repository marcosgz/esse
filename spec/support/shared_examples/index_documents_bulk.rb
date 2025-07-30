# frozen_string_literal: true

RSpec.shared_examples 'index.bulk' do |doc_type: false|
  include_context 'with venues index definition'

  let(:params) do
    doc_type ? { type: 'venue' } : {}
  end
  let(:doc_params) do
    doc_type ? { _type: 'venue' } : {}
  end
  let(:documents) do
    venues.flatten.map do |item|
      Esse::HashDocument.new(item.merge(doc_params))
    end
  end

  it 'raises an Esse::Transport::ReadonlyClusterError exception when the cluster is readonly' do
    es_client do |client, _conf, cluster|
      cluster.warm_up!
      expect(client).not_to receive(:perform_request)
      cluster.readonly = true
      expect {
        VenuesIndex.bulk(index: documents)
      }.to raise_error(Esse::Transport::ReadonlyClusterError)
    end
  end

  it 'indexes a batch of documents to the aliased index' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: true)

      resp = nil
      expect {
        resp = VenuesIndex.bulk(index: documents)
      }.not_to raise_error
      # @TODO return another object with status for each bulk operation
      expect(resp).to be_an(Array).and all(be_a(Esse::Import::RequestBody))
      expect(resp[0].stats[:index]).to eq(documents.size)
    end
  end

  it 'indexes a batch of documents to the aliased index using custom request parameters' do
    es_client do |client, _conf, cluster|
      VenuesIndex.request_params(:index, require_alias: true)
      VenuesIndex.create_index(alias: true)

      transport = cluster.api
      allow(cluster).to receive(:api).and_return(transport)
      allow(transport).to receive(:bulk).and_call_original

      resp = nil
      expect {
        resp = VenuesIndex.bulk(index: documents)
      }.not_to raise_error

      expect(transport).to have_received(:bulk).with(
        a_hash_including(
          index: VenuesIndex.name,
          require_alias: true
        )
      )
    end
  end

  it 'creates a batch of documents to the aliased index' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: true)

      resp = nil
      expect {
        resp = VenuesIndex.bulk(create: documents)
      }.not_to raise_error
      # @TODO return another object with status for each bulk operation
      expect(resp).to be_an(Array).and all(be_a(Esse::Import::RequestBody))
      expect(resp[0].stats[:create]).to eq(documents.size)
    end
  end

  it 'deletes a batch of documents to the aliased index' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: true)
      VenuesIndex.import(refresh: true, **params)

      resp = nil
      expect {
        resp = VenuesIndex.bulk(delete: documents)
      }.not_to raise_error
      # @TODO return another object with status for each bulk operation
      expect(resp).to be_an(Array).and all(be_a(Esse::Import::RequestBody))
      expect(resp[0].stats[:delete]).to eq(documents.size)
    end
  end
end
