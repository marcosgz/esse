# frozen_string_literal: true

RSpec.shared_examples 'index.bulk' do |doc_type: false|
  include_context 'with venues index definition'

  let(:params) do
    case doc_type
    when :_doc
      { type: '_doc' }
    when true
      { type: 'venue' }
    else
      {}
    end
  end
  let(:doc_params) do
    case doc_type
    when :_doc
      { _type: '_doc' }
    when true
      { _type: 'venue' }
    else
      {}
    end
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

  it 'indexes a batch of documents to the aliased index using custom request parameters' do |example|
    doc = documents[0]
    index_params = %w[1.x 2.x 5.x 6.x].include?(example.metadata[:es_version]) ? {} : { require_alias: true }

    es_client do |client, _conf, cluster|
      VenuesIndex.request_params(:index, **index_params, timeout: '10s')
      VenuesIndex.create_index(alias: true)

      transport = cluster.api
      allow(cluster).to receive(:api).and_return(transport)
      allow(transport).to receive(:bulk).and_call_original

      resp = nil
      expect {
        resp = VenuesIndex.bulk(index: [doc])
      }.not_to raise_error

      expect(transport).to have_received(:bulk).with(
        a_hash_including(
          body: contain_exactly({
            index: a_hash_including(
              **doc.to_bulk,
              **doc_params,
              **index_params,
            )
          })
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

  it 'creates a batch of documents to the aliased index using custom request parameters' do |example|
    doc = documents[0]
    create_params = %w[1.x 2.x 5.x 6.x].include?(example.metadata[:es_version]) ? {} : { require_alias: true }

    es_client do |client, _conf, cluster|
      VenuesIndex.request_params(:create, **create_params, timeout: '10s')
      VenuesIndex.create_index(alias: true)

      transport = cluster.api
      allow(cluster).to receive(:api).and_return(transport)
      allow(transport).to receive(:bulk).and_call_original
      resp = nil
      expect {
        resp = VenuesIndex.bulk(create: [doc])
      }.not_to raise_error
      expect(transport).to have_received(:bulk).with(
        a_hash_including(
          body: contain_exactly({
            create: a_hash_including(
              **doc.to_bulk,
              **doc_params,
              **create_params,
            )
          })
        )
      )
      expect(resp).to be_an(Array).and all(be_a(Esse::Import::RequestBody))
      expect(resp[0].stats[:create]).to eq(1)
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

  it 'deletes a batch of documents to the aliased index using custom request parameters' do
    doc = documents[0]
    es_client do |client, _conf, cluster|
      VenuesIndex.request_params(:index, :create, :update, routing: "custom")
      VenuesIndex.request_params(:delete, routing: "custom", timeout: '10s')
      VenuesIndex.create_index(alias: true)
      VenuesIndex.import(refresh: true, **params)

      transport = cluster.api
      allow(cluster).to receive(:api).and_return(transport)
      allow(transport).to receive(:bulk).and_call_original
      resp = nil
      expect {
        resp = VenuesIndex.bulk(delete: [doc])
      }.not_to raise_error
      expect(transport).to have_received(:bulk).with(
        a_hash_including(
          body: contain_exactly({
            delete: a_hash_including(
              **doc.to_bulk(data: false),
              **doc_params,
              routing: "custom",
            )
          })
        )
      )
      expect(resp).to be_an(Array).and all(be_a(Esse::Import::RequestBody))
      expect(resp[0].stats[:delete]).to eq(1)
    end
  end

  it 'updates a batch of documents to the aliased index' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: true)
      VenuesIndex.import(refresh: true, **params)

      doc = documents[0]
      doc.mutate(:name) { "Updated Name" }

      resp = nil
      expect {
        resp = VenuesIndex.bulk(update: [doc])
      }.not_to raise_error

      # @TODO return another object with status for each bulk operation
      expect(resp).to be_an(Array).and all(be_a(Esse::Import::RequestBody))
      expect(resp[0].stats[:update]).to eq(1)
    end
  end

  it 'updates a batch of documents to the aliased index using custom request parameters' do |example|
    update_params = %w[1.x 2.x 5.x 6.x].include?(example.metadata[:es_version]) ? {} : { retry_on_conflict: 2 }

    es_client do |client, _conf, cluster|
      VenuesIndex.request_params(:update, **update_params, timeout: '10s')
      VenuesIndex.create_index(alias: true)
      VenuesIndex.import(refresh: true, **params)

      transport = cluster.api
      allow(cluster).to receive(:api).and_return(transport)
      allow(transport).to receive(:bulk).and_call_original

      doc = documents[0]
      doc.mutate(:name) { "Updated Name" }

      resp = nil
      expect {
        resp = VenuesIndex.bulk(update: [doc])
      }.not_to raise_error
      expect(transport).to have_received(:bulk).with(
        a_hash_including(
          body: contain_exactly({
            update: a_hash_including(
              **doc.to_bulk(operation: :update),
              **doc_params,
              **update_params,
            )
          })
        )
      )
      expect(resp).to be_an(Array).and all(be_a(Esse::Import::RequestBody))
      expect(resp[0].stats[:update]).to eq(1)
    end
  end
end
