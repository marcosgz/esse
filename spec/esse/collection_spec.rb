# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Collection do
  let(:collection) { described_class.new(**options) }
  let(:options) { {} }

  it 'includes Enumerable' do
    expect(described_class).to include Enumerable
  end

  describe '#options' do
    subject { collection.options }

    let(:options) { { batch_size: 500 } }

    it { is_expected.to eq options }
  end

  describe '#each' do
    it 'raises NotImplementedError' do
      expect { collection.each }.to raise_error(NotImplementedError, 'Override this method to iterate over the collection')
    end
  end

  describe '#each_batch_ids' do
    it 'raises NotImplementedError' do
      expect { collection.each_batch_ids }.to raise_error(NotImplementedError, 'Override this method to iterate over the collection in batches of IDs')
    end
  end
end
