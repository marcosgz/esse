# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Events::Event do
  subject(:event) do
    described_class.new(event_id, payload)
  end

  let(:payload) { {} }

  describe '#[]' do
    let(:event_id) { :test }
    let(:payload) { { test: :foo } }

    it 'fetches payload key' do
      expect(event[:test]).to eq :foo
    end

    it 'returns nil' do
      expect(event[:fake]).to be_nil
    end
  end

  describe '#fetch' do
    let(:event_id) { :test }
    let(:payload) { { test: :foo } }

    it 'fetches payload key' do
      expect(event.fetch(:test)).to eq :foo
    end

    it 'raises KeyError when no key found' do
      expect { event.fetch(:fake) }.to raise_error(KeyError)
    end
  end

  describe '#key?' do
    let(:event_id) { :test }
    let(:payload) { { test: :foo } }

    it 'returns true' do
      expect(event.key?(:test)).to be true
    end

    it 'returns false' do
      expect(event.key?(:fake)).to be false
    end
  end

  describe '#payload' do
    let(:event_id) { :test }
    let(:payload) { { test: :foo } }

    it 'returns payload if no argument' do
      expect(event.payload).to eq payload
    end

    it 'returns new event with payload payload' do
      new_event = event.payload(bar: :baz)
      expect(new_event).not_to eq(event)
      expect(new_event.payload).to eq(test: :foo, bar: :baz)
    end
  end

  describe '#to_h' do
    let(:event_id) { :test }
    let(:payload) { { test: :foo } }

    it 'returns payload' do
      expect(event.to_h).to eq payload
    end
  end

  describe '#listener_method' do
    let(:event_id) { :test }

    it 'returns listener method name' do
      expect(event.listener_method).to eq :on_test
    end

    it 'replaces dots for underscores' do
      ev = described_class.new('some.custom.action')
      expect(ev.listener_method).to eq :on_some_custom_action
    end
  end
end
