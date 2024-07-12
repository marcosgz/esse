# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::LazyDocumentHeader do
  let(:doc) { described_class.new(object) }
  let(:object) { {} }
  let(:options) { {} }

  describe '#valid?' do
    it { expect(doc).to respond_to :valid? }

    it 'returns false' do
      expect(doc.valid?).to be_falsey
    end

    context 'when _id is present' do
      let(:object) { { _id: 1 } }

      it 'returns true' do
        expect(doc.valid?).to be_truthy
      end
    end
  end

  describe '#id' do
    it { expect(doc).to respond_to :id }

    it 'should raise KeyError' do
      expect { doc.id }.to raise_error
    end

    context 'when _id is present' do
      let(:object) { { _id: 1 } }

      it 'returns the _id' do
        expect(doc.id).to eq(1)
      end
    end
  end

  describe '#type' do
    it { expect(doc).to respond_to :type }

    it 'returns nil' do
      expect(doc.type).to be_nil
    end

    context 'when _type is present' do
      let(:object) { { _type: 'foo' } }

      it 'returns the _type' do
        expect(doc.type).to eq('foo')
      end
    end
  end

  describe '#routing' do
    it { expect(doc).to respond_to :routing }

    it 'returns nil' do
      expect(doc.routing).to be_nil
    end

    context 'when _routing is present' do
      let(:object) { { routing: 'foo' } }

      it 'returns the _routing' do
        expect(doc.routing).to eq('foo')
      end
    end
  end

  describe '#to_h' do
    it { expect(doc).to respond_to :to_h }

    it 'returns the object' do
      expect(doc.to_h).to eq(object)
    end

    context 'when _id is present' do
      let(:object) { { _id: 1 } }

      it 'returns the object' do
        expect(doc.to_h).to eq(object)
      end
    end

    context 'when _type is present' do
      let(:object) { { _type: 'foo' } }

      it 'returns the object' do
        expect(doc.to_h).to eq(object)
      end
    end

    context 'when routing is present' do
      let(:object) { { routing: 'foo' } }

      it 'returns the object' do
        expect(doc.to_h).to eq(object)
      end
    end
  end

  describe '.coerce' do
    it { expect(described_class).to respond_to :coerce }

    it 'returns nil' do
      expect(described_class.coerce(nil)).to be_nil
    end

    context 'when value is a LazyDocumentHeader' do
      let(:object) { described_class.new(_id: 1) }

      it 'returns the same instance' do
        expect(described_class.coerce(object)).to eq(object)
      end
    end

    context 'when value is a Esse::Document' do
      let(:object) { Esse::HashDocument.new(_id: 1) }

      it 'returns a LazyDocumentHeader instance' do
        expect(described_class.coerce(object)).to be_a(described_class)
      end
    end

    context 'when value is a Hash' do
      let(:object) { { _id: 1 } }

      it 'returns a LazyDocumentHeader instance' do
        expect(described_class.coerce(object)).to be_a(described_class)
      end
    end

    context 'when value is a String' do
      let(:object) { '1' }

      it 'returns a LazyDocumentHeader instance' do
        expect(described_class.coerce(object)).to be_a(described_class)
      end
    end

    context 'when value is a Integer' do
      let(:object) { 1 }

      it 'returns a LazyDocumentHeader instance' do
        expect(described_class.coerce(object)).to be_a(described_class)
      end
    end
  end

  describe '.coerce_each' do
    it { expect(described_class).to respond_to :coerce_each }

    it 'returns an empty array when the give argument is a nil object' do
      expect(described_class.coerce_each(nil)).to eq([])
    end

    it 'returns an empty array when the given argument is an empty array' do
      expect(described_class.coerce_each([])).to eq([])
    end

    it 'returns an array with a LazyDocumentHeader instance' do
      expect(described_class.coerce_each([{_id: 1}])).to all(be_a(described_class))
    end

    it 'returns an array with a LazyDocumentHeader instance with the given Hash' do
      expect(described_class.coerce_each(_id: 1)).to all(be_a(described_class))
    end

    it 'removes invalid instances' do
      expect(described_class.coerce_each([nil, {_id: 1}, {}]).size).to eq(1)
    end
  end

  describe '#to_doc' do
    it { expect(doc).to respond_to :to_doc }

    it 'returns a HashDocument instance' do
      expect(doc.to_doc).to be_a(Esse::HashDocument)
    end

    it 'returns a HashDocument instance with the object as source' do
      expect(doc.to_doc.source).to eq(object)
    end

    it 'returns a HashDocument instance with the object as source and the given source' do
      expect(doc.to_doc(foo: 'bar').source).to eq(object.merge(foo: 'bar'))
    end
  end
end
