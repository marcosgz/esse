# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Config do
  let(:model) { described_class.new }

  describe '.setup' do
    Esse::Config::SETUP_ATTRIBUTES.each do |name|
      context "with the #{name} writer attribute" do
        it 'allows a hash with string keys' do
          expect(model).to receive(:"#{name}=").and_return(true)

          model.setup(name.to_s => true, 'other' => false)
        end

        it 'allows a hash with symbol keys' do
          expect(model).to receive(:"#{name}=").and_return(true)

          model.setup(name.to_sym => true, :other => false)
        end
      end
    end
  end

  describe '.index_settings' do
    it { expect(model.index_settings).to eq({}) }

    it 'allows overwriting default value' do
      model.index_settings = { foo: 'bar' }
      expect(model.index_settings).to eq(foo: 'bar')
    end
  end

  describe '.index_prefix' do
    it { expect(model.index_prefix).to eq nil }

    it 'allows overwriting default value' do
      model.index_prefix = 'prefix'
      expect(model.index_prefix).to eq('prefix')
    end
  end

  describe '.client=' do
    subject { model.instance_variable_get(:@clients) }

    let(:connection) { double }

    it { expect(model).to respond_to(:"client=") }

    it 'allows define a single connection' do
      model.client = connection
      is_expected.to eq(_default: connection)
    end

    it 'allows to define multiple connections' do
      model.client = { other: connection }
      is_expected.to eq(other: connection)
    end

    it 'keeps existing connections' do
      model.client = { foo: 'foo' }
      model.client = 'test'
      model.client = { bar: 'bar' }
      model.client = 'default'

      is_expected.to eq(foo: 'foo', bar: 'bar', _default: 'default')
    end

    it 'allows define a connection from Esse module' do
      Esse.config { |c| c.client = connection }
      expect(Esse.config.client).to eq(connection)
    end
  end

  describe '.client' do
    it { expect(model).to respond_to(:client) }

    it 'retuns an instance of elasticsearch client with no key' do
      expect(model.client).to be_an_instance_of(Elasticsearch::Transport::Client)
    end

    it 'store connection using default key' do
      model.client
      expect(model.instance_variable_get(:@clients)).to have_key(:_default)
    end

    it 'returns existing connection using a custom key' do
      connection = double
      model.instance_variable_set(:@clients, { other: connection })
      expect(model.client(:other)).to eq(connection)
    end
  end

  describe '.indices_directory' do
    it 'defaults to the app/indices' do
      expect(model.indices_directory).to eq(Pathname.new('app/indices'))
    end

    it 'wraps the string path to an instance of Pathname' do
      model.indices_directory = 'lib/indices'
      expect(model.indices_directory).to eq(Pathname.new('lib/indices'))
    end
  end
end
