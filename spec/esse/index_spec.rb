# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Index do
  let(:client1) { double }
  let(:client2) { double }

  before do
    reset_config!
    Esse.configure do |conf|
      conf.cluster do |cluster|
        cluster.client = client1
      end
      conf.cluster(:v2) do |cluster|
        cluster.client = client2
      end
    end
  end

  it 'allows overwrite elasticearch client from index model' do
    c = Class.new(Esse::Index)
    c.cluster_id = :v2
    expect(c.cluster.client).to eq(client2)
  end

  it 'returns an index subclass with default elasticsearch client' do
    c = Class.new(Esse::Index)
    expect(c.cluster.client).to eq(client1)
    expect(c.superclass).to eq(Esse::Index)
  end

  it 'returns an index subclass with a v2 elasticsearch client' do
    c = Esse::Index(:v2)
    expect(c.cluster.client).to eq(client2)
    expect(c.superclass).to eq(Esse::Index)
  end

  describe '.descendants' do
    specify do
      expect(Esse::Index.descendants).to be_a_kind_of(Array)
    end
  end

  describe '.uname' do
    before { stub_index(:users) }

    it 'returns underscored class name' do
      expect(UsersIndex.uname).to eq('users_index')
    end

    it 'returns nil for anonymous classes' do
      klass = Class.new(Esse::Index)
      expect(klass.uname).to eq(nil)
    end
  end

  describe '.index_directory' do
    before { stub_index(:users) }

    it 'returns a directory using the index class location' do
      with_cluster_config do
        expect(UsersIndex.index_directory).to eq('tmp/indices/users_index')
      end
    end

    it 'includes the namespace of the index class' do
      with_cluster_config do
        allow(UsersIndex).to receive(:name).and_return('V1::UsersIndex')
        expect(UsersIndex.index_directory).to eq('tmp/indices/v1/users_index')
      end
    end

    it 'returns nil for a anonymous class' do
      with_cluster_config do
        c = Class.new(Esse::Index)
        expect(c.index_directory).to eq(nil)
      end
    end
  end

  describe '.template_dirs' do
    before { stub_index(:events) }

    it 'returns list of template directories from current index file' do
      expect(EventsIndex.template_dirs).to match_array(
        [
          'app/indices/events_index/templates',
          'app/indices/events_index'
        ],
      )
    end
  end

  describe '#bulk_wait_interval' do
    before { stub_index(:events) }

    after { Esse.config.bulk_wait_interval = 0.1 }

    it 'returns the global bulk wait interval' do
      expect(EventsIndex.bulk_wait_interval).to eq(0.1)
      Esse.config.bulk_wait_interval = 0.2
      expect(EventsIndex.bulk_wait_interval).to eq(0.2)
    end

    it 'overwrites the global bulk wait interval' do
      expect(Esse.config.bulk_wait_interval).to eq(0.1)
      EventsIndex.bulk_wait_interval = 1.5
      expect(EventsIndex.bulk_wait_interval).to eq(1.5)
      expect(Esse.config.bulk_wait_interval).to eq(0.1)
    end
  end

  describe '.index_version' do
    before { stub_index(:users) }

    it 'does not have a default value' do
      expect(UsersIndex.index_version).to eq(nil)
    end

    it 'allows to modify the index_version value' do
      UsersIndex.index_version = 'v1'
      expect(UsersIndex.index_version).to eq('v1')
    end
  end

  describe '.index_prefix' do
    before { stub_index(:users) }

    it 'default to index_prefix when its value is nil' do
      with_cluster_config(index_prefix: nil) do
        expect(UsersIndex.index_prefix).to eq(nil)
      end
    end

    it 'default to index_prefix when its value is not nil' do
      with_cluster_config(index_prefix: 'app_esse') do
        expect(UsersIndex.index_prefix).to eq('app_esse')
      end
    end

    it 'allows to modify the index_prefix value' do
      with_cluster_config(index_prefix: 'esse') do
        UsersIndex.index_prefix = 'test'
        expect(UsersIndex.index_prefix).to eq('test')
      end
    end

    it 'normalizes the index_prefix value' do
      UsersIndex.index_prefix = 'esse test'
      expect(UsersIndex.index_prefix).to eq('esse_test')
    end

    it 'allows to disable the index_prefix value' do
      UsersIndex.index_prefix = false
      expect(UsersIndex.index_prefix).to eq(nil)
    end

    it 'allows to disable the index_prefix value' do
      with_cluster_config(index_prefix: 'esse') do
        UsersIndex.index_prefix = nil
        expect(UsersIndex.index_prefix).to eq(nil)
      end
    end

    it 'updates the index name with the new prefix' do
      UsersIndex.index_prefix = 'aaa'
      expect(UsersIndex.index_name).to eq('aaa_users')
      UsersIndex.index_prefix = 'bbb'
      expect(UsersIndex.index_name).to eq('bbb_users')
      UsersIndex.index_name = 'accounts'
      expect(UsersIndex.index_name).to eq('bbb_accounts')
    end
  end

  describe '.index_name' do
    before { stub_index(:users) }

    it 'returns class name expect the "index" suffix' do
      with_cluster_config(index_prefix: nil) do
        expect(UsersIndex.index_name).to eq('users')
        expect(UsersIndex.index_name(suffix: '2022')).to eq('users_2022')
      end
    end

    it 'normalize index namespace' do
      with_cluster_config(index_prefix: nil) do
        stub_const('BusinessIntelligence::V1::UsersIndex', UsersIndex)
        allow(BusinessIntelligence::V1::UsersIndex).to receive(:name).and_return('BusinessIntelligence::V1::UsersIndex')
        expect(BusinessIntelligence::V1::UsersIndex.index_name).to eq('business_intelligence_v1_users')
      end
    end

    it 'appends index_prefix from global config' do
      with_cluster_config(index_prefix: 'esse') do
        expect(UsersIndex.index_name).to eq('esse_users')
        expect(UsersIndex.index_name(suffix: 'v1')).to eq('esse_users_v1')
      end
    end

    it 'returns nil with an abstract class' do
      with_cluster_config(index_prefix: nil) do
        klass = Class.new(Esse::Index) { self.abstract_class = true }
        expect(klass.index_name).to eq(nil)
        expect(klass.index_name(suffix: 'v2')).to eq(nil)
      end
    end

    it 'returns nil with an anonymous class' do
      with_cluster_config(index_prefix: 'esse') do
        klass = Class.new(Esse::Index)
        expect(klass.index_name).to eq(nil)
        expect(klass.index_name(suffix: 'v3')).to eq(nil)
      end
    end
  end

  describe '.abstract_class?' do
    it 'defaults to true for anonymous classes' do
      c = Class.new(Esse::Index)
      expect(c.abstract_class?).to eq(true)
      c.index_name = 'my_index'
      expect(c.abstract_class?).to eq(false)
    end

    it 'with accessor attribute set to true' do
      c = Class.new(Esse::Index) do
        self.abstract_class = true
      end
      expect(c.abstract_class?).to eq(true)
      child = stub_index(:users, c)
      expect(child.abstract_class?).to eq(false)
    end
  end

  describe '.index_name=' do
    before { stub_index(:users) }

    it 'overwrites default index_name' do
      with_cluster_config(index_prefix: nil) do
        UsersIndex.index_name = 'admins'
        expect(UsersIndex.index_name).to eq('admins')
      end
    end

    it 'overwrites default index_prefix with prefixed global config' do
      with_cluster_config(index_prefix: 'esse') do
        UsersIndex.index_name = 'admins'
        expect(UsersIndex.index_name).to eq('esse_admins')
      end
    end
  end

  describe '.repo_hash' do
    before do
      stub_index(:posts)
      stub_index(:comments)
    end

    it 'initializes with a hash' do
      expect(PostsIndex.repo_hash).to eq({})
    end

    it 'allows subclasses change their own value and it will not impact parent class' do
      PostsIndex.repo_hash[:type] = 'my type'
      expect(PostsIndex.repo_hash).to eq(type: 'my type')
      expect(CommentsIndex.repo_hash).to eq({})
      expect(Esse::Index.repo_hash).to eq({})

      PostsIndex.repo_hash = { type: 'new type' }
      expect(PostsIndex.repo_hash).to eq(type: 'new type')
      expect(CommentsIndex.repo_hash).to eq({})
      expect(Esse::Index.repo_hash).to eq({})
    end

    it 'does not inherits values from parent class' do
      Esse::Index.repo_hash[:type] = 'my type'
      expect(Esse::Index.repo_hash).to eq(type: 'my type')
      expect(CommentsIndex.repo_hash).to eq({})

      Esse::Index.repo_hash = { type: 'new type' }
      expect(Esse::Index.repo_hash).to eq(type: 'new type')
      expect(CommentsIndex.repo_hash).to eq({})

      c = Class.new(Esse::Index)
      expect(c.repo_hash).to eq({})
      Esse::Index.repo_hash = {}
    end
  end

  describe '.backend' do
    specify do
      c = Class.new(Esse::Index)
      expect(c.backend).to be_an_instance_of(Esse::Backend::Index)
    end
  end

  describe '.elasticsearch' do
    specify do
      c = Class.new(Esse::Index)
      expect(c.elasticsearch).to be_an_instance_of(Esse::Backend::Index)
    end
  end

  describe '.mapping_single_type?' do
    subject { index_class.mapping_single_type? }

    let(:index_class) { Class.new(Esse::Index) }

    context 'with elasticsearch 1.x' do
      it 'returns true' do
        expect(index_class.cluster).to receive(:engine).and_return(Esse::ClusterEngine.new(version: '1.0', distribution: 'elasticsearch'))
        expect(subject).to be_falsey
      end

      it 'allows overriding' do
        index_class.mapping_single_type = true
        expect(subject).to be_truthy
      end
    end

    context 'with elasticsearch 2.x' do
      it 'returns true' do
        expect(index_class.cluster).to receive(:engine).and_return(Esse::ClusterEngine.new(version: '2.0', distribution: 'elasticsearch'))
        expect(subject).to be_falsey
      end

      it 'allows overriding' do
        index_class.mapping_single_type = true
        expect(subject).to be_truthy
      end
    end

    context 'with elasticsearch 5.x' do
      it 'returns true' do
        expect(index_class.cluster).to receive(:engine).and_return(Esse::ClusterEngine.new(version: '5.0', distribution: 'elasticsearch'))
        expect(subject).to be_falsey
      end

      it 'allows overriding' do
        index_class.mapping_single_type = true
        expect(subject).to be_truthy
      end
    end

    context 'with elasticsearch 6.x' do
      it 'returns true' do
        expect(index_class.cluster).to receive(:engine).and_return(Esse::ClusterEngine.new(version: '6.0', distribution: 'elasticsearch'))
        expect(subject).to be_truthy
      end

      it 'allows overriding' do
        index_class.mapping_single_type = false
        expect(subject).to be_falsey
      end
    end

    context 'with elasticsearch 7.x' do
      it 'returns true' do
        expect(index_class.cluster).to receive(:engine).and_return(Esse::ClusterEngine.new(version: '7.0', distribution: 'elasticsearch'))
        expect(subject).to be_truthy
      end

      it 'allows overriding' do
        index_class.mapping_single_type = false
        expect(subject).to be_falsey
      end
    end

    context 'with opensearch 1.x' do
      it 'returns true' do
        expect(index_class.cluster).to receive(:engine).and_return(Esse::ClusterEngine.new(version: '1.0', distribution: 'opensearch'))
        expect(subject).to be_truthy
      end

      it 'allows overriding' do
        index_class.mapping_single_type = false
        expect(subject).to be_falsey
      end
    end

    context 'with opensearch 2.x' do
      it 'returns true' do
        expect(index_class.cluster).to receive(:engine).and_return(Esse::ClusterEngine.new(version: '2.0', distribution: 'opensearch'))
        expect(subject).to be_truthy
      end

      it 'allows overriding' do
        index_class.mapping_single_type = false
        expect(subject).to be_falsey
      end
    end
  end
end
