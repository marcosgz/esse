# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Serializer do
  let(:serializer) { described_class.new(object, **options) }
  let(:object) { double }
  let(:options) { {} }

  describe "#object" do
    subject { serializer.object }

    it { is_expected.to eq object }
  end

  describe "#options" do
    subject { serializer.options }

    let(:options) { { foo: :bar } }

    it { is_expected.to eq options }
  end

  describe "#id" do
    it { expect(serializer).to respond_to :id }

    it 'should raise NotImplementedError' do
      expect { serializer.id }.to raise_error NotImplementedError
    end
  end

  describe "#type" do
    it { expect(serializer).to respond_to :type }

    it 'should return nil' do
      expect(serializer.type).to be_nil
    end
  end

  describe "#routing" do
    it { expect(serializer).to respond_to :routing }

    it 'should return nil' do
      expect(serializer.routing).to be_nil
    end
  end

  describe "#meta" do
    it { expect(serializer).to respond_to :meta }

    it 'should return an empty hash' do
      expect(serializer.meta).to eq({})
    end
  end

  describe "#source" do
    it { expect(serializer).to respond_to :source }

    it 'should return an empty hash' do
      expect(serializer.source).to eq({})
    end
  end
end
