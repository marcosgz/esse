# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Index do
  let(:client1) { double }
  let(:client2) { double }

  before(:each) do
    reset_config!
    Esse.config do |conf|
      conf.client = {
        default: client1,
        v2: client2,
      }
    end
  end

  it 'allows overwrite elasticearch client from index model' do
    c = Class.new(Esse::Index)
    c.elasticsearch_client = client2
    expect(c.elasticsearch_client).to eq(client2)
  end

  it 'returns an index subclass with default elasticsearch client' do
    c = Class.new(Esse::Index)
    expect(c.elasticsearch_client).to eq(client1)
    expect(c.superclass).to eq(Esse::Index)
  end

  it 'returns an index subclass with a v2 elasticsearch client' do
    c = Esse::Index(:v2)
    expect(c.elasticsearch_client).to eq(client2)
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

  describe '.dirname' do
    it 'returns a directory where the index file is stored' do
      expect(File).to receive(:expand_path).and_return('/tmp/app/indices/users_index.rb')
      expect(Esse::Index.dirname).to include('/tmp/app/indices/users_index')
    end

    it 'returns nil for the Esse::Index' do
      expect(Esse::Index.dirname).to eq(nil)
    end

    it 'returns nil for a anonymous class' do
      c = Class.new(Esse::Index)
      expect(c.dirname).to eq(nil)
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

  describe '.index_name' do
    before { stub_index(:users) }

    it 'returns class name expect the "index" suffix' do
      Esse.config.index_prefix = nil
      expect(UsersIndex.index_name).to eq('users')
    end

    it 'appends index_prefix from global config' do
      Esse.config.index_prefix = 'esse'
      expect(UsersIndex.index_name).to eq('esse_users')
    end

    it 'returns nil with an abstract class' do
      Esse.config.index_prefix = nil
      klass = Class.new(Esse::Index) { self.abstract_class = true }
      expect(klass.index_name).to eq(nil)
      Esse.config.index_prefix = 'esse'
      expect(klass.index_name).to eq(nil)
    end

    it 'returns nil with an anonymous class' do
      Esse.config.index_prefix = nil
      klass = Class.new(Esse::Index)
      expect(klass.index_name).to eq(nil)
      Esse.config.index_prefix = 'esse'
      expect(klass.index_name).to eq(nil)
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
      Esse.config.index_prefix = nil
      UsersIndex.index_name = 'admins'
      expect(UsersIndex.index_name).to eq('admins')
    end

    it 'overwrites default index_prefix with prefixed global config' do
      Esse.config.index_prefix = 'esse'
      UsersIndex.index_name = 'admins'
      expect(UsersIndex.index_name).to eq('esse_admins')
    end
  end

  describe '.type_hash' do
    before do
      stub_index(:posts)
      stub_index(:comments)
    end

    it 'initializes with a hash' do
      expect(PostsIndex.type_hash).to eq({})
    end

    it 'allows subclasses change their own value and it will not impact parent class' do
      PostsIndex.type_hash[:type] = 'my type'
      expect(PostsIndex.type_hash).to eq(type: 'my type')
      expect(CommentsIndex.type_hash).to eq({})
      expect(Esse::Index.type_hash).to eq({})

      PostsIndex.type_hash = { type: 'new type' }
      expect(PostsIndex.type_hash).to eq(type: 'new type')
      expect(CommentsIndex.type_hash).to eq({})
      expect(Esse::Index.type_hash).to eq({})
    end

    it 'does not inherits values from parent class' do
      Esse::Index.type_hash[:type] = 'my type'
      expect(Esse::Index.type_hash).to eq(type: 'my type')
      expect(CommentsIndex.type_hash).to eq({})

      Esse::Index.type_hash = { type: 'new type' }
      expect(Esse::Index.type_hash).to eq(type: 'new type')
      expect(CommentsIndex.type_hash).to eq({})

      c = Class.new(Esse::Index)
      expect(c.type_hash).to eq({})
    end
  end

  describe '.backend' do
    specify do
      c = Class.new(Esse::Index)
      expect(c.backend).to be_an_instance_of(Esse::Backend::Index)
    end
  end
end
