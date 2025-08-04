# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Index::RequestConfigurable do
  let(:index) { Class.new(Esse::Index) }
  let(:document) { instance_double(Esse::Document) }

  before do
    reset_config!
  end

  describe '.extended' do
    it 'extends the DSL module' do
      klass = Class.new do
        extend Esse::Index::RequestConfigurable
      end

      expect(klass.singleton_class.included_modules).to include(Esse::Index::RequestConfigurable::DSL)
      expect(klass).to respond_to(:request_params)
    end
  end

  describe '.request_params' do
    it 'adds request parameters for valid operations' do
      index.request_params(:index, key: 'value')
      expect(index.request_params_for(:index, document)).to eq({ key: 'value' })
    end

    it 'raises an error for invalid operations' do
      expect { index.request_params(:invalid_operation, key: 'value') }.to raise_error(ArgumentError, 'Invalid operation: invalid_operation')
    end
  end

  describe '.request_params_for' do
    it 'returns an empty hash if no request params exist for the operation' do
      expect(index.request_params_for(:index, document)).to eq({})
    end

    it 'combines static and dynamic request params' do
      index.request_params(:index, key: 'static_value') do |doc|
        { dynamic_key: doc }
      end
      expect(index.request_params_for(:index, 'dynamic_value')).to eq({ key: 'static_value', dynamic_key: 'dynamic_value' })
    end

    it 'merges multiple request params for the same operation' do
      index.request_params(:index, key1: 'value1')
      index.request_params(:index) do |doc|
        { key2: doc }
      end
      expect(index.request_params_for(:index, 'dynamic_value')).to eq({ key1: 'value1', key2: 'dynamic_value' })
    end

    context 'when retrieving bulk params on :index operation' do
      before do
        index.request_params(:index,
          _index: 'test_index',
          _type: 'test_type',
          routing: 'test_routing',
          if_primary_term: 1,
          if_seq_no: 2,
          version: 3,
          version_type: 'external',
          dynamic_templates: { test: { match: 'test*', mapping: { type: 'keyword' } } },
          pipeline: 'test_pipeline',
          require_alias: true,
          # non-bulk params
          timeout: '30s',
          refresh: true,
          wait_for_active_shards: 'all'
        )
      end

      it 'returns the correct bulk params' do
        expected_params = {
          _index: 'test_index',
          _type: 'test_type',
          routing: 'test_routing',
          if_primary_term: 1,
          if_seq_no: 2,
          version: 3,
          version_type: 'external',
          dynamic_templates: { test: { match: 'test*', mapping: { type: 'keyword' } } },
          pipeline: 'test_pipeline',
          require_alias: true,
        }
        expect(index.request_params_for(:index, document, bulk: true)).to eq(expected_params)
      end
    end

    context 'when retrieving bulk params on :create operation' do
      before do
        index.request_params(:create,
          _index: 'test_index',
          _type: 'test_type',
          routing: 'test_routing',
          if_primary_term: 1,
          if_seq_no: 2,
          version: 3,
          version_type: 'external',
          dynamic_templates: { test: { match: 'test*', mapping: { type: 'keyword' } } },
          pipeline: 'test_pipeline',
          require_alias: true,
          # non-bulk params
          timeout: '30s',
          refresh: true,
          wait_for_active_shards: 'all'
        )
      end

      it 'returns the correct bulk params' do
        expected_params = {
          _index: 'test_index',
          _type: 'test_type',
          routing: 'test_routing',
          if_primary_term: 1,
          if_seq_no: 2,
          version: 3,
          version_type: 'external',
          dynamic_templates: { test: { match: 'test*', mapping: { type: 'keyword' } } },
          pipeline: 'test_pipeline',
          require_alias: true,
        }
        expect(index.request_params_for(:create, document, bulk: true)).to eq(expected_params)
      end
    end

    context 'when retrieving bulk params on :update operation' do
      before do
        index.request_params(:update,
          _index: 'test_index',
          _type: 'test_type',
          routing: 'test_routing',
          if_primary_term: 1,
          if_seq_no: 2,
          version: 3,
          version_type: 'external',
          require_alias: true,
          retry_on_conflict: 3,
          # non-bulk params
          timeout: '30s',
          refresh: true,
          wait_for_active_shards: 'all'
        )
      end

      it 'returns the correct bulk params' do
        expected_params = {
          _index: 'test_index',
          _type: 'test_type',
          routing: 'test_routing',
          if_primary_term: 1,
          if_seq_no: 2,
          version: 3,
          version_type: 'external',
          require_alias: true,
          retry_on_conflict: 3,
        }
        expect(index.request_params_for(:update, document, bulk: true)).to eq(expected_params)
      end
    end

    context 'when retrieving bulk params on :delete operation' do
      before do
        index.request_params(:delete,
          _index: 'test_index',
          _type: 'test_type',
          routing: 'test_routing',
          if_primary_term: 1,
          if_seq_no: 2,
          version: 3,
          version_type: 'external',
          # non-bulk params
          timeout: '30s',
          refresh: true,
          wait_for_active_shards: 'all'
        )
      end

      it 'returns the correct bulk params' do
        expected_params = {
          _index: 'test_index',
          _type: 'test_type',
          routing: 'test_routing',
          if_primary_term: 1,
          if_seq_no: 2,
          version: 3,
          version_type: 'external',
        }
        expect(index.request_params_for(:delete, document, bulk: true)).to eq(expected_params)
      end
    end
  end

  describe '.request_params_for?' do
    it 'returns true if request params exist for the operation' do
      index.request_params(:index, key: 'value')
      expect(index.request_params_for?(:index)).to be true
    end

    it 'returns false if no request params exist for the operation' do
      expect(index.request_params_for?(:nonexistent)).to be false
    end
  end

  describe described_class::RequestParams do
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
        entry = Esse::Index::RequestConfigurable::RequestParams.new(:index, { key: 'value' })
        container.add(:index, entry)
        expect(container.key?(:index)).to be true
        expect(entries = container.instance_variable_get(:@entries)).to be_frozen
        expect(entries.values).to all(be_frozen)
      end
    end

    describe '#retrieve' do
      it 'retrieves merged hashes for the given operation' do
        entry1 = Esse::Index::RequestConfigurable::RequestParams.new(:index, { key1: 'value1' })
        entry2 = Esse::Index::RequestConfigurable::RequestParams.new(:index, { key2: 'value2' })
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
        entry1 = Esse::Index::RequestConfigurable::RequestParams.new(:index, { 'static' => 'value' })
        entry2 = Esse::Index::RequestConfigurable::RequestParams.new(:index) do |doc|
          { 'dynamic' => doc }
        end
        container.add(:index, entry1)
        container.add(:index, entry2)

        result = container.retrieve(:index, 'dynamic_value')
        expect(result).to eq({ static: 'value', dynamic: 'dynamic_value' })
      end
    end
  end
end
