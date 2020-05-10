# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Backend::Index do
  before do
    stub_index(:dummies)
  end

  describe '.exist?' do
    context 'when index does not exists' do
      specify do
        es_client { expect(DummiesIndex.backend.exist?).to eq(false) }
      end
    end

    context 'when index exists' do
      specify do
        es_client do
          DummiesIndex.backend.create_index!
          expect(DummiesIndex.backend.exist?).to eq(true)
        end
      end
    end
  end
end
