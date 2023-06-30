# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse do
  it 'has a version number' do
    expect(Esse::VERSION).not_to be nil
  end

  describe '.config' do
    it { expect(described_class).to respond_to(:config) }
    it { expect(described_class).not_to respond_to(:"config=") }
    it { expect(described_class.config).to be_an_instance_of(Esse::Config) }
    it { expect { described_class.config(&:to_s) }.not_to raise_error }
  end

  describe '.timestamp' do
    it { expect(Esse.timestamp).to be_kind_of(String) }
  end

  describe '.doc_id!' do
    specify do
      hash = {}
      id, newhash = Esse.doc_id!(hash)
      expect(id).to eq(nil)
      expect(newhash).to eq(hash)
    end

    specify do
      hash = { id: 1, foo: :bar }
      id, newhash = Esse.doc_id!(hash)
      expect(id).to eq(1)
      expect(newhash).to eq(hash)
      expect(hash).to eq(hash)
    end

    specify do
      hash = { 'id' => 1, 'foo' => :bar }
      id, newhash = Esse.doc_id!(hash)
      expect(id).to eq(1)
      expect(newhash).to eq(hash)
      expect(hash).to eq(hash)
    end

    specify do
      hash = { id: 1, foo: :bar }
      id, newhash = Esse.doc_id!(hash)
      expect(id).to eq(1)
      expect(newhash).to eq(hash)
      expect(hash).to eq(hash)
    end

    specify do
      hash = { _id: 1, id: 2, foo: :bar }
      id, newhash = Esse.doc_id!(hash)
      expect(id).to eq(1)
      expect(newhash).to eq(id: 2, foo: :bar)
      expect(hash).to eq(hash)
    end

    specify do
      hash = { '_id' => 1, 'id' => 2, 'foo' => :bar }
      id, newhash = Esse.doc_id!(hash)
      expect(id).to eq(1)
      expect(newhash).to eq('id' => 2, 'foo' => :bar)
      expect(hash).to eq(hash)
    end

    specify do
      hash = { '_id' => nil, 'id' => 2, 'foo' => :bar }
      id, newhash = Esse.doc_id!(hash)
      expect(id).to eq(2)
      expect(newhash).to eq('id' => 2, 'foo' => :bar)
      expect(hash).to eq(hash)
    end
  end

  describe '.document?' do
    specify { expect(Esse.document?(nil)).to eq(false) }
    specify { expect(Esse.document?({})).to eq(false) }
    specify { expect(Esse.document?(Class.new.new)).to eq(false) }
    specify { expect(Esse.document?(Class.new(Esse::Index).new)).to eq(false) }

    context 'with a class that inherit Esse::Serializer' do
      let(:doc_class) do
        Class.new(Esse::Serializer) do
          def initialize(*)
          end

          def id
            1
          end
        end
      end
      let(:doc) { doc_class.new }

      specify { expect(Esse.document?(doc)).to eq(true) }
    end
  end
end
