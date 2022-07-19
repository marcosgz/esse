# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::HashDocument do
  let(:document) { described_class.new(payload) }
  let(:payload) { {} }

  describe '#object' do
    subject { document.object }

    it { is_expected.to eq payload }
  end

  describe '#id' do
    specify do
      expect(described_class.new('id' => '1').id).to eq('1')
    end

    specify do
      expect(described_class.new(id: '1').id).to eq('1')
    end

    specify do
      expect(described_class.new(_id: '1').id).to eq('1')
    end

    specify do
      expect(described_class.new(id: '1').id).to eq('1')
    end

    specify do
      expect(described_class.new(other: '1').id).to eq(nil)
    end
  end

  describe '#type' do
    specify do
      expect(described_class.new('_type' => 'foo').type).to eq('foo')
    end

    specify do
      expect(described_class.new('type' => 'foo').type).to eq(nil)
    end

    specify do
      expect(described_class.new(_type: 'foo').type).to eq('foo')
    end

    specify do
      expect(described_class.new(type: 'foo').type).to eq(nil)
    end
  end

  describe '#routing' do
    specify do
      expect(described_class.new('_routing' => 'foo').routing).to eq('foo')
    end

    specify do
      expect(described_class.new('routing' => 'foo').routing).to eq(nil)
    end

    specify do
      expect(described_class.new(_routing: 'foo').routing).to eq('foo')
    end

    specify do
      expect(described_class.new(routing: 'foo').routing).to eq(nil)
    end
  end

  describe '#meta' do
    it 'should return an empty hash' do
      expect(document.meta).to eq({})
    end
  end

  describe '#source' do
    it 'should return an empty hash' do
      expect(document.source).to eq({})
    end

    it 'removes the _id, _type and _routing' do
      payload = { _id: '1', _type: 'foo', _routing: 'bar', foo: 'bar' }
      expect(described_class.new(payload).source).to eq(foo: 'bar')
    end
  end
end
