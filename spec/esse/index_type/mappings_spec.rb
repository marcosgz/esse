# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::IndexType do
  describe '.mapping_properties' do
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

    it 'does not adds the properties key' do
      expect(GeosIndex::County.mapping_properties).to eq(
        'name' => { 'type' => 'string' },
      )

      expect(GeosIndex::City.mapping_properties).to eq(
        'name' => { 'type' => 'string' },
      )
    end
  end

  describe '.mappings class definition' do
    specify do
      expect {
        Class.new(Esse::Index) do
          define_type :test do
            mappings do
            end
          end
        end
      }.not_to raise_error
    end

    specify do
      expect {
        Class.new(Esse::Index) do
          define_type :test do
            mappings({})
          end
        end
      }.not_to raise_error
    end
  end

  before do
    reset_config!
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
