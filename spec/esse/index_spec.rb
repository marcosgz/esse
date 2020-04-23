# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Index do
  let(:client1) { double }
  let(:client2) { double }

  before do
    Esse.config do |conf|
      conf.client = {
        _default: client1,
        v2: client2
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
    it 'defaults to false' do
      c = Class.new(Esse::Index)
      expect(c.abstract_class?).to eq(false)
    end

    it 'with accessor attribute set to true' do
      c = Class.new(Esse::Index) do
        self.abstract_class = true
      end
      expect(c.abstract_class?).to eq(true)
      child = Class.new(c)
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
end
