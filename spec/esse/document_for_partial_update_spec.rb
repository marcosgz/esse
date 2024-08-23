# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/VerifiedDoubles
RSpec.describe Esse::DocumentForPartialUpdate do
  let(:document) { described_class.new(obj, source: source) }
  let(:obj) { double(id: 1) }
  let(:source) { { foo: :bar } }

  describe '#object' do
    subject { document.object }

    it { is_expected.to be obj }
  end

  describe '#id' do
    subject { document.id }

    it { is_expected.to eq 1 }
  end

  describe '#type' do
    subject { document.type }

    let(:obj) { double(id: 1, type: 'foo', source: source) }

    it { is_expected.to eq 'foo' }
  end

  describe '#routing' do
    subject { document.routing }

    let(:obj) { double(id: 1, routing: 'foo', source: source) }

    it { is_expected.to eq 'foo' }
  end

  describe '#source' do
    subject { document.source }

    let(:obj) { double(id: 1, source: { original: 'source' }) }

    it { is_expected.to eq source }
  end
end
