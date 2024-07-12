# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::ArrayUtils do
  describe '.wrap' do
    specify do
      expect(described_class.wrap(nil)).to eq([])
    end

    specify do
      expect(described_class.wrap('a')).to eq(['a'])
    end

    specify do
      expect(described_class.wrap(['a'])).to eq(['a'])
    end

    specify do
      expect(described_class.wrap(%w[a b])).to eq(%w[a b])
    end

    specify do
      expect(described_class.wrap({a: :b}).to_a).to eq([{a: :b}])
    end
  end
end
