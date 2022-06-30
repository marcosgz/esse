# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Collection do
  let(:collection) { described_class.new(**options) }
  let(:options) { {} }

  it "includes Enumerable" do
    expect(described_class).to include Enumerable
  end

  describe "#options" do
    subject { serializer.options }

    let(:options) { { batch_size: 500 } }

    it { is_expected.to eq options }
  end
end
