# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::NullDocument do
  let(:document) { described_class.new }

  describe '#object' do
    subject { document.object }

    it { is_expected.to eq(nil) }
  end

  describe '#id' do
    specify do
      expect(document.id).to eq(nil)
      expect(document).to be_ignore_on_index
      expect(document).to be_ignore_on_delete
    end
  end

  describe '#type' do
    specify do
      expect(document.type).to eq(nil)
    end
  end

  describe '#routing' do
    specify do
      expect(document.routing).to eq(nil)
    end
  end

  describe '#meta' do
    specify do
      expect(document.meta).to eq({})
    end
  end

  describe '#source' do
    specify do
      expect(document.source).to eq(nil)
    end
  end
end
