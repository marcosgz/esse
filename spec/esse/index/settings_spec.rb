# frozen_string_literal: true

require 'spec_helper'
require 'support/esse_config'

RSpec.describe Esse::Index do
  before do
    reset_esse_config
  end

  describe '.setting' do
    subject { EventsIndex.send(:setting) }
    before { stub_index(:events) }

    it { is_expected.to be_an_instance_of(Esse::IndexSetting) }
  end

  describe '.settings' do
    subject { EventsIndex.send(:setting).body }

    context 'with a hash definition' do
      before do
        stub_index(:events) { settings(number_of_replicas: 4) }
      end

      specify do
        is_expected.to eq(number_of_replicas: 4)
      end

      specify do
        Esse.config do |c|
          c.index_settings = { number_of_replicas: 3, refresh_interval: '1s' }
        end
        is_expected.to eq(number_of_replicas: 4, refresh_interval: '1s')
      end
    end

    context 'with a hash definition' do
      before do
        stub_index(:events) do
          settings do
            { number_of_replicas: '4'.to_i }
          end
        end
      end

      specify do
        is_expected.to eq(number_of_replicas: 4)
      end

      specify do
        Esse.config do |c|
          c.index_settings = { number_of_replicas: 3, refresh_interval: '1s' }
        end
        is_expected.to eq(number_of_replicas: 4, refresh_interval: '1s')
      end
    end
  end

  describe '.settings_hash' do
    context 'without the settings node' do
      before do
        stub_index(:geos) do
          settings do
            { 'number_of_replicas' => '4'.to_i }
          end
        end
      end

      specify do
        expect(GeosIndex.settings_hash).to eq(
          'settings' => { 'number_of_replicas' => 4 },
        )
      end
    end

    context 'with the settings node' do
      before do
        stub_index(:geos) do
          settings do
            {
              'settings' => { 'number_of_replicas' => '6'.to_i }
            }
          end
        end
      end

      specify do
        expect(GeosIndex.settings_hash).to eq(
          'settings' => { 'number_of_replicas' => 6 },
        )
      end
    end
  end
end
