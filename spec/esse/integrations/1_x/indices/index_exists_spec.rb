# frozen_string_literal: true

require 'spec_helper'

stack_describe '1.x', 'elasticsearch index exist' do
  before do
    stub_index(:dummies)
  end

  describe '.exist?' do
    context 'when index does not exists' do
      specify do
        es_client { expect(DummiesIndex.elasticsearch.exist?).to eq(false) }
      end
    end

    context 'when index exists' do
      specify do
        es_client do
          DummiesIndex.elasticsearch.create_index!
          expect(DummiesIndex.elasticsearch.exist?).to eq(true)
        end
      end
    end
  end
end
