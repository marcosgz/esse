# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::LazyDocumentHeader do
  let(:doc) { described_class.new(**object.merge(options)) }
  let(:object) { { id: nil } }
  let(:options) { {} }

  describe '#valid?' do
    it { expect(doc).to respond_to :valid? }

    it 'returns false' do
      expect(doc.valid?).to be_falsey
    end

    context 'when id is present' do
      let(:object) { { id: 1 } }

      it 'returns true' do
        expect(doc.valid?).to be_truthy
      end
    end
  end

  describe '#id' do
    it { expect(doc).to respond_to :id }

    context 'when id is present' do
      let(:object) { { id: 1 } }

      it 'returns the id' do
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
      let(:object) { { id: 1, type: 'foo' } }

      it 'returns the type' do
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
      let(:object) { { id: 1, routing: 'foo' } }

      it 'returns the _routing' do
        expect(doc.routing).to eq('foo')
      end
    end
  end

  describe '#to_h' do
    it { expect(doc).to respond_to :to_h }

    it 'returns the object' do
      expect(doc.to_h).to eq(_id: nil)
    end

    context 'when _id is present' do
      let(:object) { { id: 1 } }

      it 'returns the object' do
        expect(doc.to_h).to eq(_id: 1)
      end
    end

    context 'when _type is present' do
      let(:object) { { id: 2, type: 'foo' } }

      it 'returns the object' do
        expect(doc.to_h).to eq(_id: 2, _type: 'foo')
      end
    end

    context 'when routing is present' do
      let(:object) { { id: 3, routing: 'foo' } }

      it 'returns the object' do
        expect(doc.to_h).to eq(_id: 3, routing: 'foo')
      end
    end
  end

  describe '.coerce' do
    it { expect(described_class).to respond_to :coerce }

    it 'returns nil' do
      expect(described_class.coerce(nil)).to be_nil
    end

    context 'when value is a LazyDocumentHeader' do
      let(:object) { described_class.new(id: 1) }

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

    context 'when value is a document with id in options' do
      let(:object) do
        Class.new(Esse::Document) do
          def options
            { id: 1 }
          end

          def id
            2
          end
        end.new(nil)
      end

      it 'returns a LazyDocumentHeader instance with the proper id' do
        instance = described_class.coerce(object)
        expect(instance).to be_a(described_class)
        expect(instance.id).to eq(2)
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

    it 'flattens the array' do
      expect(described_class.coerce_each([[{_id: 1}], {_id: 2}]).size).to eq(2)
    end

    it 'coerces a list of Esse::Document instances' do
      list = [Esse::HashDocument.new(_id: 1), Class.new(Esse::HashDocument).new(_id: 2)]
      expect(described_class.coerce_each(list)).to all(be_a(described_class))
    end
  end

  describe '#to_doc' do
    let(:options) { { admin: true } }
    let(:object) { { id: 1, routing: 'il', type: 'state' } }

    it { expect(doc).to respond_to :to_doc }

    it 'returns a Esse::Document instance' do
      expect(doc.to_doc).to be_a(Esse::Document)
    end

    it 'returns a Esse::Document instance with the id' do
      expect(doc.to_doc.id).to eq(1)
    end

    it 'returns a Esse::Document instance routing' do
      expect(doc.to_doc.routing).to eq('il')
    end

    it 'returns a Esse::Document instance with the type' do
      expect(doc.to_doc.type).to eq('state')
    end

    it 'returns a Esse::Document instance with the options' do
      expect(doc.to_doc.options).to eq(admin: true)
    end

    it 'returns a Esse::Document instance with the object as source and the given source' do
      new_doc = doc.to_doc(foo: 'bar')
      expect(new_doc.source).to eq(foo: 'bar')
      expect(new_doc.object).to eq(doc)
      expect(new_doc.options).to eq(admin: true)
    end
  end

  describe '#options' do
    it { expect(doc).to respond_to :options }

    it 'returns an empty hash' do
      expect(doc.options).to eq({})
    end

    context 'when options are present' do
      let(:options) { { foo: 'bar' } }

      it 'returns the options' do
        expect(doc.options).to eq(options)
      end
    end
  end
end
