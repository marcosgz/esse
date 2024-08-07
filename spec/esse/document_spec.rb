# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Document do
  let(:serializer) { described_class.new(object, **options) }
  let(:object) { double }
  let(:options) { {} }

  describe '#object' do
    subject { serializer.object }

    it { is_expected.to eq object }
  end

  describe '#options' do
    subject { serializer.options }

    let(:options) { { foo: :bar } }

    it { is_expected.to eq options }
  end

  describe '#id' do
    it { expect(serializer).to respond_to :id }

    it 'should raise NotImplementedError' do
      expect { serializer.id }.to raise_error NotImplementedError
    end
  end

  describe '#type' do
    it { expect(serializer).to respond_to :type }

    it 'should return nil' do
      expect(serializer.type).to be_nil
    end
  end

  describe '#routing' do
    it { expect(serializer).to respond_to :routing }

    it 'should return nil' do
      expect(serializer.routing).to be_nil
    end
  end

  describe '#meta' do
    it { expect(serializer).to respond_to :meta }

    it 'should return an empty hash' do
      expect(serializer.meta).to eq({})
    end
  end

  describe '#source' do
    it { expect(serializer).to respond_to :source }

    it 'should return an empty hash' do
      expect(serializer.source).to eq({})
    end
  end

  describe '#to_bulk' do
    let(:document_class) do
      Class.new(described_class) do
        def id
          1
        end

        def type
          'foo'
        end

        def routing
          'bar'
        end

        def meta
          { timeout: 10 }
        end

        def source
          { foo: 'bar' }
        end
      end
    end

    let(:document) { document_class.new(object, **options) }

    context 'with data: true' do
      subject { document.to_bulk(data: true) }

      it { is_expected.to eq(_id: 1, _type: 'foo', routing: 'bar', timeout: 10, data: { foo: 'bar' }) }
    end

    context 'with data: false' do
      subject { document.to_bulk(data: false) }

      it { is_expected.to eq(_id: 1, _type: 'foo', routing: 'bar', timeout: 10) }
    end

    context 'with operation: :update' do
      subject { document.to_bulk(data: true, operation: :update) }

      it { is_expected.to eq(_id: 1, _type: 'foo', routing: 'bar', timeout: 10, data: { doc: { foo: 'bar' } }) }
    end

    context 'when document does not have a routing' do
      it 'should not include the routing' do
        allow(document).to receive(:routing).and_return(nil)
        expect(document.to_bulk(data: true)).to eq(_id: 1, _type: 'foo', timeout: 10, data: { foo: 'bar' })
      end
    end

    context 'when document does not have a type' do
      it 'should not include the type' do
        allow(document).to receive(:type).and_return(nil)
        expect(document.to_bulk(data: true)).to eq(_id: 1, routing: 'bar', timeout: 10, data: { foo: 'bar' })
      end
    end

    context 'when document does not have a meta' do
      it 'should not include the meta' do
        allow(document).to receive(:meta).and_return({})
        expect(document.to_bulk(data: true)).to eq(_id: 1, _type: 'foo', routing: 'bar', data: { foo: 'bar' })
      end
    end

    context 'when document does not have a source' do
      it 'should not include the source' do
        allow(document).to receive(:source).and_return({})
        expect(document.to_bulk(data: true)).to eq(_id: 1, _type: 'foo', routing: 'bar', timeout: 10, data: {})
      end
    end
  end

  describe '#doc_header' do
    let(:document_class) do
      Class.new(described_class) do
        def id
          1
        end

        def type
          'foo'
        end

        def routing
          'bar'
        end
      end
    end

    let(:document) { document_class.new(object, **options) }

    subject { document.doc_header }

    it { is_expected.to eq(_id: 1, _type: 'foo', routing: 'bar') }

    context 'when document does not have a routing' do
      it 'should not include the routing' do
        allow(document).to receive(:routing).and_return(nil)
        expect(document.doc_header).to eq(_id: 1, _type: 'foo')
      end
    end

    context 'when document does not have a type' do
      it 'should not include the type' do
        allow(document).to receive(:type).and_return(nil)
        expect(document.doc_header).to eq(_id: 1, routing: 'bar')
      end
    end

    context 'when the document includes options' do
      let(:options) { { foo: 'bar' } }

      it { is_expected.to eq(_id: 1, _type: 'foo', routing: 'bar', foo: 'bar') }
    end
  end

  describe '#mutate' do
    let(:document_class) do
      Class.new(described_class) do
        def source
          { foo: 'foo' }
        end
      end
    end

    let(:document) { document_class.new(object, **options) }

    it 'adds the given value to the :mutated_source' do
      expect {
        document.mutate(:bar) { 'bar' }
      }.not_to change(document, :source)

      expect(document.send(:mutated_source)).to eq(foo: 'foo', bar: 'bar')
    end
  end
end
