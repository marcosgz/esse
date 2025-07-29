# frozen_string_literal: true

RSpec.shared_examples 'index.update' do |doc_type: false|
  include_context 'with venues index definition'

  let(:params) do
    doc_type ? { type: 'venue' } : {}
  end
  let(:doc_params) do
    doc_type ? { _type: 'venue' } : {}
  end
  let(:index_suffix) { SecureRandom.hex(8) }

  it 'raises an Esse::Transport::ReadonlyClusterError exception when the cluster is readonly' do
    es_client do |client, _conf, cluster|
      cluster.warm_up!
      expect(client).not_to receive(:perform_request)
      cluster.readonly = true
      expect {
        VenuesIndex.update(id: 1, body: { doc: { name: 'New Name' } }, **params)
      }.to raise_error(Esse::Transport::ReadonlyClusterError)
    end
  end

  it 'raises an Esse::Transport::ServerError exception when api throws an error' do
    es_client do |client, _conf, cluster|
      expect {
        VenuesIndex.update(id: -1, body: { doc: { name: 'foo' } }, **params)
      }.to raise_error(Esse::Transport::NotFoundError)
    end
  end

  it 'raises ArgumentError when the :id is not provided' do
    es_client do |client, _conf, cluster|
      expect {
        VenuesIndex.update(body: { doc: { name: 'foo' } }, **params)
      }.to raise_error(ArgumentError, 'missing keyword: id')
    end
  end

  it 'raises ArgumentError when the :body is not provided' do
    es_client do |client, _conf, cluster|
      expect {
        VenuesIndex.update(id: 1, **params)
      }.to raise_error(ArgumentError, 'missing keyword: body')
    end
  end

  it 'updates the document in the aliased index' do |example|
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: true, suffix: index_suffix)
      VenuesIndex.import(refresh: true, suffix: index_suffix, **params)

      resp = nil
      expect {
        resp = VenuesIndex.update(id: 1, body: { doc: { name: 'New Name' } }, **params)
      }.not_to raise_error
      unless %w[1.x 2.x].include?(example.metadata[:es_version])
        expect(resp['result']).to eq('updated')
      end

      resp = VenuesIndex.get(id: 1)
      expect(resp['_source']).to include('name' => 'New Name')
    end
  end

  it 'updates the document in the unaliased index' do |example|
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: false, suffix: index_suffix)
      VenuesIndex.import(refresh: true, suffix: index_suffix, **params)

      resp = nil
      expect {
        resp = VenuesIndex.update(id: 1, body: { doc: { name: 'New Name' } }, suffix: index_suffix, **params)
      }.not_to raise_error
      unless %w[1.x 2.x].include?(example.metadata[:es_version])
        expect(resp['result']).to eq('updated')
      end

      resp = VenuesIndex.get(id: 1, suffix: index_suffix)
      expect(resp['_source']).to include('name' => 'New Name')
    end
  end

  context 'when using an Esse::Document instance' do
    let(:doc_class) do
      Class.new(Esse::HashDocument)
    end
    let(:document) { doc_class.new(id: 1, name: 'New Name', **doc_params) }

    it 'updates the document using the instance of Esse::Document' do |example|
      es_client do |client, _conf, cluster|
        VenuesIndex.create_index(alias: true)
        VenuesIndex.import(refresh: true, **params)

        resp = nil
        expect {
          resp = VenuesIndex.update(document)
        }.not_to raise_error

        unless %w[1.x 2.x].include?(example.metadata[:es_version])
          expect(resp['result']).to eq('updated')
        end

        resp = VenuesIndex.get(id: 1)
        expect(resp['_source']).to include('name' => 'New Name')
      end
    end

    it 'updates the document using custom params from cluster' do |example|
      es_client do |client, _conf, cluster|
        VenuesIndex.create_index(alias: true)
        VenuesIndex.import(refresh: true, **params)

        cluster.request_params(:update, retry_on_conflict: 3)
        cluster.request_params(:delete, timeout: -1)

        transport = cluster.api
        allow(cluster).to receive(:api).and_return(transport)
        allow(transport).to receive(:update).and_call_original
        resp = nil
        expect {
          resp = VenuesIndex.update(document, refresh: true)
        }.not_to raise_error

        expect(cluster.api).to have_received(:update).with(
          index: VenuesIndex.index_name,
          id: 1,
          retry_on_conflict: 3,
          refresh: true,
          body: an_instance_of(Hash),
        )

        unless %w[1.x 2.x].include?(example.metadata[:es_version])
          expect(resp['result']).to eq('updated')
        end

        resp = VenuesIndex.get(id: 1)
        expect(resp['_source']).to include('name' => 'New Name')
      end
    end

    it 'updates the document using custom params from index' do |example|
      es_client do |client, _conf, cluster|
        VenuesIndex.request_params(:update, retry_on_conflict: 2)
        VenuesIndex.request_params(:delete, timeout: -1)

        VenuesIndex.create_index(alias: true)
        VenuesIndex.import(refresh: true, **params)

        transport = cluster.api
        allow(cluster).to receive(:api).and_return(transport)
        allow(transport).to receive(:update).and_call_original
        resp = nil
        expect {
          resp = VenuesIndex.update(document, refresh: true)
        }.not_to raise_error

        expect(cluster.api).to have_received(:update).with(
          index: VenuesIndex.index_name,
          id: 1,
          retry_on_conflict: 2,
          refresh: true,
          body: an_instance_of(Hash),
        )

        unless %w[1.x 2.x].include?(example.metadata[:es_version])
          expect(resp['result']).to eq('updated')
        end

        resp = VenuesIndex.get(id: 1)
        expect(resp['_source']).to include('name' => 'New Name')
      end
    end
  end
end
