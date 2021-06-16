# frozen_string_literal: true

require 'spec_helper'

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
      }.to raise_error(SyntaxError)
    end
  end
end
