# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Cluster do
  let(:model) { described_class.new(id: :v1) }

  describe '#id' do
    context do
      let(:model) { described_class.new(id: :v1) }

      it { expect(model.id).to eq(:v1) }
    end

    context do
      let(:model) { described_class.new(id: 'v2') }

      it { expect(model.id).to eq(:v2) }
    end
  end

  describe 'initialization properties' do
    specify do
      model = described_class.new(id: :v1)
      expect(model.settings).to eq({})
      expect(model.mappings).to eq({})
    end

    specify do
      model = described_class.new(id: :v1, settings: { refresh_interval: '1s' })
      expect(model.settings).to eq(refresh_interval: '1s')
    end

    specify do
      model = described_class.new(id: :v1, mappings: { foo: 'bar' })
      expect(model.mappings).to eq(foo: 'bar')
    end
  end

  describe '#assign' do
    let(:model) { described_class.new(id: :v1) }

    specify do
      expect(model.settings).to eq({})
      expect { model.assign(settings: { refresh_interval: '1s' }, other: 1) }.not_to raise_error
      expect(model.settings).to eq(refresh_interval: '1s')
    end

    specify do
      expect(model.settings).to eq({})
      expect { model.assign('settings' => { 'refresh_interval' => '1s' }, 'other' => 1) }.not_to raise_error
      expect(model.settings).to eq('refresh_interval' => '1s')
    end

    specify do
      expect(model.mappings).to eq({})
      expect { model.assign(mappings: { foo: 'bar' }, other: 1) }.not_to raise_error
      expect(model.mappings).to eq(foo: 'bar')
    end

    specify do
      expect(model.mappings).to eq({})
      expect { model.assign('mappings' => { 'foo' => 'bar' }, 'other' => 1) }.not_to raise_error
      expect(model.mappings).to eq('foo' => 'bar')
    end

    specify do
      expect(model.wait_for_status).to eq(nil)
      expect { model.assign(wait_for_status: 'yellow') }.not_to raise_error
      expect(model.wait_for_status).to eq('yellow')
    end

    specify do
      expect(model.readonly?).to eq(false)
      expect { model.assign(readonly: true) }.not_to raise_error
      expect(model.readonly?).to eq(true)
    end
  end

  describe '#readonly?' do
    it { expect(model.readonly?).to eq(false) }

    it 'allows overwriting default value' do
      model.readonly = true
      expect(model.readonly?).to eq(true)
    end
  end

  describe '#throw_error_when_readonly!' do
    it 'raises an error when the cluster is readonly' do
      model.readonly = true
      expect {
        model.throw_error_when_readonly!
      }.to raise_error(Esse::Transport::ReadonlyClusterError)
    end

    it 'does not raise an error when the cluster is not readonly' do
      expect {
        model.throw_error_when_readonly!
      }.not_to raise_error
    end
  end

  describe '#wait_for_status' do
    it { expect(model.wait_for_status).to eq(nil) }

    it 'sets the value for wait_for_status' do
      model.wait_for_status = 'green'
      expect(model.wait_for_status).to eq('green')
    end
  end

  describe '#wait_for_status!' do
    let(:api) { instance_double(Esse::Transport) }

    before do
      allow(model).to receive(:api).and_return(api)
    end

    it 'checks for the cluster health using the given status' do
      expect(api).to receive(:health).with(wait_for_status: 'green').and_return(:ok)
      expect(model.wait_for_status!(status: 'green')).to eq(:ok)
    end

    it 'checks for the cluster health using the status from config' do
      expect(api).to receive(:health).with(wait_for_status: 'yellow').and_return(:ok)
      model.wait_for_status = :yellow
      expect(model.wait_for_status!).to eq(:ok)
    end

    it 'does not sends any request to elasticsearch when wait for status is not defined' do
      expect(api).not_to receive(:health)
      expect(model.wait_for_status!).to eq(nil)
    end
  end

  describe '#settings' do
    it { expect(model.settings).to eq({}) }

    it 'allows overwriting default value' do
      model.settings = { foo: 'bar' }
      expect(model.settings).to eq(foo: 'bar')
    end
  end

  describe '#index_prefix' do
    it { expect(model.index_prefix).to eq nil }

    it 'allows overwriting default value' do
      model.index_prefix = 'prefix'
      expect(model.index_prefix).to eq('prefix')
    end
  end

  describe '#client=', service_type: :elasticsearch do
    it { expect(model).to respond_to(:'client=') }

    it 'defines a connection from hash' do
      expect(Elasticsearch::Client).to receive(:new).with({hosts: []}).and_return(client = double)

      expect {
        model.client = { hosts: [] }
      }.not_to raise_error
      expect(model.client).to eq(client)
    end

    it 'allows set a Elasticsearch::Client instance as client' do
      client = Elasticsearch::Client.new
      expect {
        model.client = client
      }.not_to raise_error
      expect(model.client).to eq(client)
    end
  end

  describe '#client=', service_type: :opensearch do
    it { expect(model).to respond_to(:'client=') }

    it 'defines a connection from hash' do
      expect(OpenSearch::Client).to receive(:new).with(hosts: []).and_return(client = double)

      expect {
        model.client = { hosts: [] }
      }.not_to raise_error
      expect(model.client).to eq(client)
    end

    it 'allows set a OpenSearch::Client instance as client' do
      client = OpenSearch::Client.new
      expect {
        model.client = client
      }.not_to raise_error
      expect(model.client).to eq(client)
    end
  end

  describe '#client', service_type: :elasticsearch do
    it { expect(model).to respond_to(:client) }

    it 'retuns an instance of elasticsearch as default' do
      expect(model.instance_variable_get(:@client)).to eq(nil)
      if defined? Elasticsearch::Transport::Client
        expect(model.client).to be_an_instance_of(Elasticsearch::Transport::Client)
        expect(model.instance_variable_get(:@client)).to be_an_instance_of(Elasticsearch::Transport::Client)
      else # Elasticsearch-ruby >= 8.0
        expect(model.client).to be_an_instance_of(Elasticsearch::Client)
        expect(model.instance_variable_get(:@client)).to be_an_instance_of(Elasticsearch::Client)
      end
    end

    it 'store connection using default key' do
      expect(model.instance_variable_get(:@client)).to eq(nil)
      client = Elasticsearch::Client.new
      model.client = client
      expect(model.client).to eq(client)
      expect(model.instance_variable_get(:@client)).to eq(client)
    end
  end

  describe '#client', service_type: :opensearch do
    it { expect(model).to respond_to(:client) }

    it 'retuns an instance of elasticsearch as default' do
      expect(model.instance_variable_get(:@client)).to eq(nil)
      expect(model.client).to be_an_instance_of(OpenSearch::Client)
      expect(model.instance_variable_get(:@client)).to be_an_instance_of(OpenSearch::Client)
    end

    it 'store connection using default key' do
      expect(model.instance_variable_get(:@client)).to eq(nil)
      client = OpenSearch::Client.new
      model.client = client
      expect(model.client).to eq(client)
      expect(model.instance_variable_get(:@client)).to eq(client)
    end
  end

  describe '#info' do
    subject { model.info }

    context 'with elasticsearch 1.x', es_version: '1.x' do
      specify do
        body = elasticsearch_response_fixture(file: 'info', version: '1.x', assigns: { version__number: version = '1.7.6' })
        stub_es_request(:get, '/', res: { body: body })
        expect(subject).to eq(
          distribution: 'elasticsearch',
          version: version,
        )
      end
    end

    context 'with elasticsearch 2.x', es_version: '2.x' do
      specify do
        body = elasticsearch_response_fixture(file: 'info', version: '2.x', assigns: { version__number: version = '2.0.0' })
        stub_es_request(:get, '/', res: { body: body })
        expect(subject).to eq(
          distribution: 'elasticsearch',
          version: version,
        )
      end
    end

    context 'with elasticsearch 5.x', es_version: '5.x' do
      specify do
        body = elasticsearch_response_fixture(file: 'info', version: '5.x', assigns: { version__number: version = '5.0.0' })
        stub_es_request(:get, '/', res: { body: body })
        expect(subject).to eq(
          distribution: 'elasticsearch',
          version: version,
        )
      end
    end

    context 'with elasticsearch 6.x', es_version: '6.x' do
      specify do
        body = elasticsearch_response_fixture(file: 'info', version: '6.x', assigns: { version__number: version = '6.0.0' })
        stub_es_request(:get, '/', res: { body: body })
        expect(subject).to eq(
          distribution: 'elasticsearch',
          version: version,
        )
      end
    end

    context 'with elasticsearch 7.x', es_version: '7.x' do
      specify do
        body = elasticsearch_response_fixture(file: 'info', version: '7.x', assigns: { version__number: version = '7.0.0' })
        stub_es_request(:get, '/', res: { body: body })
        expect(subject).to eq(
          distribution: 'elasticsearch',
          version: version,
        )
      end
    end

    context 'with elasticsearch 8.x', es_version: '8.x' do
      specify do
        body = elasticsearch_response_fixture(file: 'info', version: '8.x', assigns: { version__number: version = '8.0.0' })
        stub_es_request(:get, '/', res: { body: body })
        expect(subject).to eq(
          distribution: 'elasticsearch',
          version: version,
        )
      end
    end

    context 'with opensearch 1.x', es_version: '1.x', distribution: 'opensearch' do
      specify do
        body = elasticsearch_response_fixture(file: 'info', version: '1.x', distribution: 'opensearch', assigns: { version__number: version = '1.0.0' })
        stub_es_request(:get, '/', res: { body: body })
        expect(subject).to eq(
          distribution: 'opensearch',
          version: version,
        )
      end
    end

    context 'with opensearch 2.x', es_version: '2.x', distribution: 'opensearch' do
      specify do
        body = elasticsearch_response_fixture(file: 'info', version: '2.x', distribution: 'opensearch', assigns: { version__number: version = '2.0.0' })
        stub_es_request(:get, '/', res: { body: body })
        expect(subject).to eq(
          distribution: 'opensearch',
          version: version,
        )
      end
    end
  end

  describe '#engine' do
    it 'returns an instance of ClusterEngine' do
      expect(model).to receive(:info).and_return(
        distribution: 'elasticsearch',
        version: '7.0.0',
      )
      expect(model.engine).to be_an_instance_of(Esse::ClusterEngine)
    end
  end

  describe '#api' do
    it 'returns an instance of Esse::Transport' do
      expect(model.api).to be_an_instance_of(Esse::Transport)
    end
  end

  describe '#search' do
    before do
      stub_index(:posts)
      stub_index(:comments)
    end

    it 'returns an instance of Search::Query' do
      expect(query = model.search(PostsIndex, body: { query: { match_all: {}} }, limit: 10)).to be_an_instance_of(Esse::Search::Query)
      expect(query.definition).to eq({
        index: PostsIndex.index_name,
        body: {
          query: {
            match_all: {},
          },
        },
        limit: 10
      })
    end

    it 'combines multiple indices' do
      expect(query = model.search(PostsIndex, CommentsIndex, body: { query: { match_all: {}} })).to be_an_instance_of(Esse::Search::Query)
      expect(query.definition).to eq({
        index: [PostsIndex.index_name, CommentsIndex.index_name].join(','),
        body: {
          query: {
            match_all: {},
          },
        },
      })
    end

    it 'allows string and symbols as index' do
      expect(query = model.search('posts_index', :comments_index, body: { query: { match_all: {}} })).to be_an_instance_of(Esse::Search::Query)
      expect(query.definition).to eq({
        index: 'posts_index,comments_index',
        body: {
          query: {
            match_all: {},
          },
        },
      })
    end

    it "raises an error if indices aren't allowed" do
      expect {
        model.search(nil, body: { query: { match_all: {}} })
      }.to raise_error(ArgumentError).with_message(/Invalid index type: nil/)
    end
  end
end
