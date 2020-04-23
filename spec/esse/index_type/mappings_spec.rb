# frozen_string_literal: true

require 'spec_helper'
require 'support/esse_config'

RSpec.describe Esse::IndexType do
  describe '.mappings class definition' do
    specify do
      expect {
        Class.new(Esse::IndexType) do
          mappings do
          end
        end
      }.not_to raise_error
    end

    specify do
      expect {
        Class.new(Esse::IndexType) do
          mappings({})
        end
      }.not_to raise_error
    end
  end

  before do
    reset_esse_config
  end

  describe '.mapping' do
    subject { EventsIndex::Event.send(:mapping) }
    before { stub_index(:events) { define_type(:event) } }

    it { is_expected.to be_an_instance_of(Esse::Types::Mapping) }
  end

  describe '.mappings' do
    subject { EventsIndex::Event.send(:mapping).body }

    context 'with a hash definition' do
      before do
        stub_index(:events) do
          define_type :event do
            mappings(title: { type: 'string' })
          end
        end
      end

      specify do
        is_expected.to eq(title: { type: 'string' })
      end
    end

    context 'with a hash definition' do
      before do
        stub_index(:events) do
          define_type :event do
            mappings do
              { title: { type: :string.to_s } }
            end
          end
        end
      end

      specify do
        is_expected.to eq(title: { type: 'string' })
      end
    end
  end
end
