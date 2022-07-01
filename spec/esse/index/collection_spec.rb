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

      col_proc = klass.repo.instance_variable_get(:@collection_proc)
      expect(col_proc).to eq(DummyGeosCollection)
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
end
