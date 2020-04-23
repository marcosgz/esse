# frozen_string_literal: true

require 'spec_helper'
require 'support/esse_config'

RSpec.describe Esse::IndexType do
  describe '.mappings_hash' do
    before do
      stub_index(:geos) do
        define_type :county do
          mappings('properties' => { 'name' => { 'type' => 'string' } })
        end

        define_type :city do
          mappings('name' => { 'type' => 'string' })
        end
      end
    end

    specify do
      expect(GeosIndex::County.mappings_hash).to eq(
        'county' => {
          'properties' => {
            'name' => { 'type' => 'string' }
          }
        },
      )
      expect(GeosIndex::City.mappings_hash).to eq(
        'city' => {
          'properties' => {
            'name' => { 'type' => 'string' }
          }
        },
      )
    end
  end

  describe '.mappings class definition' do
    specify do
      expect {
        Class.new(Esse::IndexType) do
          def self.type_name
            'test'
          end

          mappings do
          end
        end
      }.not_to raise_error
    end

    specify do
      expect {
        Class.new(Esse::IndexType) do
          def self.type_name
            'test'
          end

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

    it { is_expected.to be_an_instance_of(Esse::IndexMapping) }
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
