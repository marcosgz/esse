# frozen_string_literal: true

RSpec.shared_examples 'index.delete' do |doc_type: false|
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
        VenuesIndex.delete(id: 1, **params)
      }.to raise_error(Esse::Transport::ReadonlyClusterError)
    end
  end

  it 'raises an Esse::Transport::ServerError exception when api throws an error' do
    es_client do |client, _conf, cluster|
      expect {
        VenuesIndex.delete(id: -1, **params)
      }.to raise_error(Esse::Transport::NotFoundError)
    end
  end

  it 'raises ArgumentError when the :id is not provided' do
    es_client do |client, _conf, cluster|
      expect {
        VenuesIndex.delete
      }.to raise_error(ArgumentError, 'missing keyword: id')
    end
  end

  it 'raises ArgumentError when the :id is nil' do
    es_client do |client, _conf, cluster|
      expect {
        VenuesIndex.delete(id: nil, **params)
      }.to raise_error(ArgumentError, "Required argument 'id' missing")
    end
  end

  it 'deletes the document from the aliased index' do |example|
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: true, suffix: index_suffix)
      VenuesIndex.import(refresh: true, suffix: index_suffix, **params)

      resp = nil
      expect {
        resp = VenuesIndex.delete(id: 1, **params)
      }.not_to raise_error
      if %w[1.x 2.x].include?(example.metadata[:es_version])
        expect(resp['found']).to eq(true)
      else
        expect(resp['result']).to eq('deleted')
      end
    end
  end

  it 'deletes the document from the unaliased index' do |example|
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: false, suffix: index_suffix)
      VenuesIndex.import(refresh: true, suffix: index_suffix, **params)

      resp = nil
      expect {
        resp = VenuesIndex.delete(id: 1, suffix: index_suffix, **params)
      }.not_to raise_error
      if %w[1.x 2.x].include?(example.metadata[:es_version])
        expect(resp['found']).to eq(true)
      else
        expect(resp['result']).to eq('deleted')
      end
    end
  end

  it 'deletes the document using the instance of Esse::Document' do |example|
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: true, suffix: index_suffix)
      VenuesIndex.import(refresh: true, suffix: index_suffix, **params)

      document = Esse::HashDocument.new(id: 1, **doc_params)
      resp = nil
      expect {
        resp = VenuesIndex.delete(document)
      }.not_to raise_error
      if %w[1.x 2.x].include?(example.metadata[:es_version])
        expect(resp['found']).to eq(true)
      else
        expect(resp['result']).to eq('deleted')
      end
    end
  end
end
