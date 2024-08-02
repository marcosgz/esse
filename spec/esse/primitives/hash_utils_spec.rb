# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::HashUtils do
  describe '#deep_transform_keys' do
    specify do
      expect(described_class.deep_transform_keys({'a' => {'b' => 'c'}}, &:to_sym)).to eq(a: {b: 'c'})
    end
  end

  describe '#deep_merge' do
    specify do
      expect(described_class.deep_merge({a: {b: 'c'}}, {a: {d: 'e'}})).to eq(a: {b: 'c', d: 'e'})
    end
  end

  describe '#deep_merge!' do
    specify do
      hash = {a: {b: 'c'}}
      described_class.deep_merge!(hash, {a: {d: 'e'}})
      expect(hash).to eq(a: {b: 'c', d: 'e'})
    end
  end

  describe '#explode_keys' do
    specify do
      expect(described_class.explode_keys({'a.b' => 'c'})).to eq('a' => {'b' => 'c'})
    end

    specify do
      expect(described_class.explode_keys({'a.b.c': 'd'})).to eq(a: {b: {c: 'd'}})
    end
  end
end
