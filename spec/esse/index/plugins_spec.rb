# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Index, '.plugin' do
  it "raises Load error if the plugin can't be loaded" do
    expect {
      Class.new(Esse::Index) do
        plugin 'undefined_plugin'
      end
    }.to raise_error(LoadError)
  end

  it 'extends the index with IndexClassMethods of the plugin' do
    plug = Module.new do
      self::IndexClassMethods = Module.new do
        def foo
          :foo
        end
      end
    end
    klass = Class.new(Esse::Index)
    expect(klass.plugins).not_to include(plug)
    klass.plugin(plug)
    expect(klass.plugins).to include(plug)
    expect(klass.foo).to eq(:foo)
  end

  it 'extends the index repository with RepositoryClassMethods of the plugin' do
    plug = Module.new do
      self::RepositoryClassMethods = Module.new do
        def bar
          :bar
        end
      end
    end
    klass = Class.new(Esse::Index)
    klass.repository(:foo)
    expect(klass.repo(:foo)).not_to respond_to(:bar)
    klass.plugin(plug)
    expect(klass.repo(:foo)).to respond_to(:bar)
    expect(klass.repo(:foo).bar).to eq(:bar)
  end

  it 'extends new repositories with RepositoryClassMethods even plugin previously loaded' do
    plug = Module.new do
      self::RepositoryClassMethods = Module.new do
        def bar
          :bar
        end
      end
    end
    klass = Class.new(Esse::Index) do
      plugin(plug)
    end
    klass.repository(:foo)
    expect(klass.repo(:foo)).to respond_to(:bar)
    expect(klass.repo(:foo).bar).to eq(:bar)
  end

  it 'does not extend repositories multiple types with the same plugin' do
    plug = Module.new do
      self::RepositoryClassMethods = Module.new do
        def bar
          :bar
        end
      end
    end
    klass = Class.new(Esse::Index) do
      repository(:one)
      plugin(plug)
    end
    expect(klass.repo(:one)).to respond_to(:bar)
    expect(klass.repo(:one)).not_to receive(:extend).with(plug::RepositoryClassMethods)
    klass.repository(:two)
    expect(klass.repo(:two)).to respond_to(:bar)
  end

  it 'calls apply and configure on the plugin' do
    plug = Module.new do
      def self.apply(index_class, foo: nil, **)
        index_class.send(:define_singleton_method, :foo) { foo }
      end

      def self.configure(index_class, bar: nil, **)
        index_class.send(:define_singleton_method, :bar) { bar }
      end
    end
    klass = Class.new(Esse::Index)
    expect(klass.plugins).not_to include(plug)
    klass.plugin(plug, foo: 'foo', bar: 'bar')
    expect(klass.plugins).to include(plug)
    expect(klass.foo).to eq('foo')
    expect(klass.bar).to eq('bar')
  end

  it 'calls configure every time when the plugin is loaded' do
    plug = Module.new do
      def self.apply(index_class, **)
        index_class.class_eval do
          class << self
            attr_accessor :count
          end
        end
        index_class.count = 0
      end

      def self.configure(index_class, **)
        index_class.count += 1
      end
    end
    klass = Class.new(Esse::Index)
    expect(klass.plugins).not_to include(plug)
    klass.plugin(plug)
    expect(klass.plugins).to include(plug)
    expect(klass.count).to eq(1)
    klass.plugin(plug)
    expect(klass.count).to eq(2)
  end

  it 'should have inherited_instance_variables add instance variables to copy into the subclass' do
    plug = Module.new do
      def self.apply(index_class)
        index_class.instance_variable_set(:@plugin_domain, 'foo')
      end

      # rubocop:disable Lint/ConstantDefinitionInBlock
      module self::IndexClassMethods
        attr_reader :plugin_domain

        Esse::Plugins.inherited_instance_variables(self, :@plugin_domain => :dup)
      end
      # rubocop:enable Lint/ConstantDefinitionInBlock
    end
    klass = Class.new(Esse::Index)
    klass.plugin plug
    expect(Class.new(klass).plugin_domain).to eq('foo')
  end
end

RSpec.describe 'Esse::Index.plugin' do
  before do
    @index_class = Class.new(Esse::Index)
  end

  it 'tries to load plugins from esse/plugins/:plugin' do
    a = []
    m = Module.new
    @index_class.define_singleton_method(:require) do |b|
      a << b
      Esse::Plugins.const_set(:MyAwesomePlugin, m)
    end
    @index_class.plugin :my_awesome_plugin
    expect(@index_class.plugins).to include(m)
    expect(a).to eq(['esse/plugins/my_awesome_plugin'])
    Esse::Plugins.send(:remove_const, :MyAwesomePlugin)
  end
end
