# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::HashUtils do
  describe '#deep_transform_keys' do
    specify do
      expect(described_class.deep_transform_keys({'a' => {'b' => 'c'}}, &:to_sym)).to eq(a: {b: 'c'})
    end
  end
end
