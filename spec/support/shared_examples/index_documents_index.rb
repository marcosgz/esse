# frozen_string_literal: true

RSpec.shared_examples 'index.index' do |doc_type: false|
  include_context 'with venues index definition'

  let(:params) do
    doc_type ? { type: 'venue' } : {}
  end
  let(:doc_params) do
    doc_type ? { _type: 'venue' } : {}
  end

  it 'raises an Esse::Transport::ReadonlyClusterError exception when the cluster is readonly' do
    es_client do |client, _conf, cluster|
      cluster.warm_up!
      expect(client).not_to receive(:perform_request)
      cluster.readonly = true
      expect {
        VenuesIndex.index(id: 1, body: { name: 'New Name' }, **params)
      }.to raise_error(Esse::Transport::ReadonlyClusterError)
    end
  end

  it 'raises ArgumentError when the :id is not provided' do
    es_client do |client, _conf, cluster|
      expect {
        VenuesIndex.index(body: { name: 'Restaurant' }, **params)
      }.to raise_error(ArgumentError, 'missing keyword: id')
    end
  end

  it 'raises ArgumentError when the :body is not provided' do
    es_client do |client, _conf, cluster|
      expect {
        VenuesIndex.index(id: 1, **params)
      }.to raise_error(ArgumentError, 'missing keyword: body')
    end
  end

  it 'indexes a new document in the aliased index' do |example|
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: true)

      resp = nil
      expect {
        resp = VenuesIndex.index(id: 1, body: { name: 'New Name' }, **params)
      }.not_to raise_error
      if %w[1.x 2.x].include?(example.metadata[:es_version])
        expect(resp['created']).to eq(true)
      else
        expect(resp['result']).to eq('created')
      end

      resp = VenuesIndex.get(id: 1)
      expect(resp['_source']).to include('name' => 'New Name')
    end
  end

  it 'updates the document in the aliased index' do |example|
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: true)
      VenuesIndex.import(refresh: true, **params)

      resp = nil
      expect {
        resp = VenuesIndex.index(id: 1, body: { name: 'New Name' }, **params)
      }.not_to raise_error
      if %w[1.x 2.x].include?(example.metadata[:es_version])
        expect(resp['_version']).to eq(2)
      else
        expect(resp['result']).to eq('updated')
      end

      resp = VenuesIndex.get(id: 1)
      expect(resp['_source']).to include('name' => 'New Name')
    end
  end

  it 'indexes a new document in the unaliased index' do |example|
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: false, suffix: '2022')

      resp = nil
      expect {
        resp = VenuesIndex.index(id: 1, body: { name: 'New Name' }, suffix: '2022', **params)
      }.not_to raise_error
      if %w[1.x 2.x].include?(example.metadata[:es_version])
        expect(resp['created']).to eq(true)
      else
        expect(resp['result']).to eq('created')
      end
      expect(resp['_index']).to eq("#{cluster.index_prefix}_venues_2022")

      resp = VenuesIndex.get(id: 1, suffix: '2022')
      expect(resp['_source']).to include('name' => 'New Name')
    end
  end

  it 'updates the document in the unaliased index' do |example|
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: false, suffix: '2022')
      VenuesIndex.import(refresh: true, suffix: '2022', **params)

      resp = nil
      expect {
        resp = VenuesIndex.index(id: 1, body: { name: 'New Name' }, suffix: '2022', **params)
      }.not_to raise_error
      if %w[1.x 2.x].include?(example.metadata[:es_version])
        expect(resp['_version']).to eq(2)
      else
        expect(resp['result']).to eq('updated')
      end
      expect(resp['_index']).to eq("#{cluster.index_prefix}_venues_2022")

      resp = VenuesIndex.get(id: 1, suffix: '2022')
      expect(resp['_source']).to include('name' => 'New Name')
    end
  end

  it 'indexes the document using the instance of Esse::Document' do |example|
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: true)

      document = Esse::HashDocument.new(id: 1, name: 'New Name', **doc_params)
      resp = nil
      expect {
        resp = VenuesIndex.index(document)
      }.not_to raise_error
      if %w[1.x 2.x].include?(example.metadata[:es_version])
        expect(resp['created']).to eq(true)
      else
        expect(resp['result']).to eq('created')
      end

      resp = VenuesIndex.get(id: 1)
      expect(resp['_source']).to include('name' => 'New Name')
    end
  end
end
