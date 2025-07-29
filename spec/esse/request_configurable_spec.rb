# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::RequestConfigurable do
  let(:dummy_class) do
    Class.new do
      include Esse::RequestConfigurable
    end
  end

  let(:document) { instance_double(Esse::Document) }

  describe described_class::RequestEntry do
    describe '#call' do
      context 'when no block is provided' do
        it 'returns the hash' do
          entry = described_class.new(:index, { key: 'value' })
          expect(entry.call(document)).to eq({ key: 'value' })
        end
      end

      context 'when a block is provided' do
        it 'merges the block result with the hash' do
          entry = described_class.new(:index, { key: 'value' }) do |doc|
            { dynamic_key: doc }
          end
          expect(entry.call('dynamic_value')).to eq({ key: 'value', dynamic_key: 'dynamic_value' })
        end

        it 'raises an error if the block result is not a hash' do
          entry = described_class.new(:index, { key: 'value' }) do |_doc|
            'invalid_result'
          end
          expect { entry.call(document) }.to raise_error(ArgumentError, 'Expected a Hash, got String')
        end
      end
    end
  end

  describe described_class::Container do
    let(:container) { described_class.new }

    describe '#add' do
      it 'adds an entry for the given operation' do
        entry = Esse::RequestConfigurable::RequestEntry.new(:index, { key: 'value' })
        container.add(:index, entry)
        expect(container.key?(:index)).to be true
        expect(entries = container.instance_variable_get(:@entries)).to be_frozen
        expect(entries.values).to all(be_frozen)
      end
    end

    describe '#retrieve' do
      it 'retrieves merged hashes for the given operation' do
        entry1 = Esse::RequestConfigurable::RequestEntry.new(:index, { key1: 'value1' })
        entry2 = Esse::RequestConfigurable::RequestEntry.new(:index, { key2: 'value2' })
        container.add(:index, entry1)
        expect(container.instance_variable_get(:@entries)).to be_frozen
        container.add(:index, entry2)
        expect(container.instance_variable_get(:@entries)).to be_frozen

        result = container.retrieve(:index, document)
        expect(result).to eq({ key1: 'value1', key2: 'value2' })
        expect(container.instance_variable_get(:@entries)).to be_frozen
      end

      it 'returns an empty hash if no entries exist for the operation' do
        expect(container.retrieve(:nonexistent, document)).to eq({})
      end

      it 'symbolizes keys in the result' do
        entry1 = Esse::RequestConfigurable::RequestEntry.new(:index, { 'static' => 'value' })
        entry2 = Esse::RequestConfigurable::RequestEntry.new(:index) do |doc|
          { 'dynamic' => doc }
        end
        container.add(:index, entry1)
        container.add(:index, entry2)

        result = container.retrieve(:index, 'dynamic_value')
        expect(result).to eq({ static: 'value', dynamic: 'dynamic_value' })
      end
    end
  end

  describe 'ClassMethods' do
    describe '.request_params' do
      it 'adds request parameters for valid operations' do
        dummy_class.request_params(:index, key: 'value')
        expect(dummy_class.request_params_for(:index, document)).to eq({ key: 'value' })
      end

      it 'raises an error for invalid operations' do
        expect { dummy_class.request_params(:invalid_operation, key: 'value') }.to raise_error(ArgumentError, 'Invalid operation: invalid_operation')
      end
    end

    describe '.request_body' do
      it 'adds request body for valid operations' do
        dummy_class.request_body(:create, key: 'value')
        expect(dummy_class.request_body_for(:create, document)).to eq({ key: 'value' })
      end

      it 'raises an error for invalid operations' do
        expect { dummy_class.request_body(:invalid_operation, key: 'value') }.to raise_error(ArgumentError, 'Invalid operation: invalid_operation')
      end
    end

    describe '.request_params_for' do
      it 'returns an empty hash if no request params exist for the operation' do
        expect(dummy_class.request_params_for(:index, document)).to eq({})
      end

      it 'combines static and dynamic request params' do
        dummy_class.request_params(:index, key: 'static_value') do |doc|
          { dynamic_key: doc }
        end
        expect(dummy_class.request_params_for(:index, 'dynamic_value')).to eq({ key: 'static_value', dynamic_key: 'dynamic_value' })
      end

      it 'merges multiple request params for the same operation' do
        dummy_class.request_params(:index, key1: 'value1')
        dummy_class.request_params(:index) do |doc|
          { key2: doc }
        end
        expect(dummy_class.request_params_for(:index, 'dynamic_value')).to eq({ key1: 'value1', key2: 'dynamic_value' })
      end
    end

    describe '.request_body_for' do
      it 'returns an empty hash if no request body exists for the operation' do
        expect(dummy_class.request_body_for(:create, document)).to eq({})
      end

      it 'combines static and dynamic request body' do
        dummy_class.request_body(:create, key: 'static_value') do |doc|
          { dynamic_key: doc }
        end
        expect(dummy_class.request_body_for(:create, 'dynamic_value')).to eq({ key: 'static_value', dynamic_key: 'dynamic_value' })
      end

      it 'merges multiple request bodies for the same operation' do
        dummy_class.request_body(:create, key1: 'value1')
        dummy_class.request_body(:create) do |doc|
          { key2: doc }
        end
        expect(dummy_class.request_body_for(:create, 'dynamic_value')).to eq({ key1: 'value1', key2: 'dynamic_value' })
      end
    end
  end
end
