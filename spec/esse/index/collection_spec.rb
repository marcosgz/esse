# frozen_string_literal: true

require 'spec_helper'
require 'support/collections'

RSpec.describe Esse::Index do
  describe '.collection' do
    specify do
      expect {
        stub_index(:geos) do
          collection {}
        end
      }.not_to raise_error
    end

    specify do
      klass = Class.new(Esse::Index) do
        collection do |&b|
          b.call([])
        end
      end

      proc = klass.instance_variable_get(:@collection_proc)
      expect { |b| proc.call(&b).to yield_with_args([]) }
    end

    specify do
      expect {
        Class.new(Esse::Index) do
          collection
        end
      }.to raise_error(ArgumentError)
    end

    specify do
      klass = Class.new(Esse::Index) do
        collection DummyGeosCollection
      end

      proc = klass.instance_variable_get(:@collection_proc)
      expect(proc).to eq(DummyGeosCollection)
    end

    it 'raises an error if the collection does not implement Enumerable interface' do
      collection_klass = Class.new
      expect {
        Class.new(Esse::Index) do
          collection collection_klass
        end
      }.to raise_error(ArgumentError)
    end
  end

  describe '.each_batch' do
    context 'without the collection definition' do
      before do
        stub_index(:users) do
        end
      end

      specify do
        expect {
          UsersIndex.each_batch { |batch| puts batch }
        }.to raise_error(NotImplementedError, 'there is no collection defined for the "UsersIndex" index')
      end
    end

    context 'without collection data' do
      before do
        stub_index(:users) do
          collection do
          end
        end
      end

      it 'does not raise any exception' do
        expect { |b| UsersIndex.each_batch(&b) }.not_to yield_control
      end
    end

    context 'with the collection definition' do
      before do
        stub_index(:users) do
          collection do |opts, &block|
            [[1], [2], [3]].each do |batch|
              block.call batch, opts
            end
          end
        end
      end

      it 'yields each block with arguments' do
        o = { active: true }
        expect { |b| UsersIndex.each_batch(o, &b) }.to yield_successive_args([[1], o], [[2], o], [[3], o])
      end
    end

    context 'with a collection class' do
      before do
        stub_index(:geos) do
          collection DummyGeosCollection
        end
      end

      it 'yields each block with arguments' do
        f = { active: true }
        o = { repo: (1..6), batch_size: 2 }.merge(f)
        expect { |b| GeosIndex.each_batch(o, &b) }.to yield_successive_args([[1, 2], f], [[3, 4], f], [[5, 6], f])
      end
    end
  end
end
