# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Index do
  before do
    reset_config!
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
        stub_index(:events) { settings(index: { number_of_replicas: 4 }) }
      end

      it 'returns the settings hash form index settings' do
        with_cluster_config(settings: {}) do
          expect(subject).to eq(index: { number_of_replicas: 4 })
        end
      end

      it 'merges the settings with the cluster settings' do
        with_cluster_config(settings: { index: { number_of_replicas: 3, refresh_interval: '1s' } }) do
          expect(subject).to eq(index: { number_of_replicas: 4, refresh_interval: '1s' })
        end
      end
    end

    context 'with a hash definition' do
      before do
        stub_index(:events) do
          settings do
            { index: { number_of_replicas: '4'.to_i } }
          end
        end
      end

      it 'returns the settings hash form index settings' do
        expect(subject).to eq(index: { number_of_replicas: 4 })
      end

      it 'merges the settings with the cluster settings' do
        with_cluster_config(settings: { index: { number_of_replicas: 3, refresh_interval: '1s' } }) do
          expect(subject).to eq(index: { number_of_replicas: 4, refresh_interval: '1s' })
        end
      end
    end
  end

  describe '.settings_hash' do
    context 'with imploded settings' do
      before do
        stub_index(:geos) do
          settings do
            { 'index.number_of_replicas' => '4'.to_i }
          end
        end
      end

      it 'explodes the settings' do
        expect(GeosIndex.settings_hash).to eq(
          settings: { index: { number_of_replicas: 4 } },
        )
      end
    end

    context 'with simplified settings' do
      before do
        stub_index(:geos) do
          settings do
            {
              number_of_shards: 1,
              number_of_replicas: 4,
              refresh_interval: '1s',
            }
          end
        end
      end

      it 'moves the simplified settings to the :index key' do
        expect(GeosIndex.settings_hash).to eq(
          settings: { index: {
            number_of_shards: 1,
            number_of_replicas: 4,
            refresh_interval: '1s'
          } },
        )
      end
    end

    context 'without the settings root key' do
      before do
        stub_index(:geos) do
          settings do
            { 'index' => { 'number_of_replicas' => '4'.to_i } }
          end
        end
      end

      specify do
        expect(GeosIndex.settings_hash).to eq(
          settings: { index: { number_of_replicas: 4 } },
        )
      end

      specify do
        with_cluster_config(settings: { index: { refresh_interval: '1s', number_of_replicas: 2 } }) do
          expect(GeosIndex.settings_hash).to eq(
            settings: {
              index: {
                refresh_interval: '1s',
                number_of_replicas: 4,
              }
            },
          )
        end
      end

      it 'merges the given settings with the index settings' do
        expect(GeosIndex.settings_hash(settings: { index: { refresh_interval: '-1' } })).to eq(
          settings: {
            index: {
              refresh_interval: '-1',
              number_of_replicas: 4,
            }
          }
        )
      end

      it 'merges the given imploded settings with the index settings' do
        expect(GeosIndex.settings_hash(settings: { 'index.refresh_interval': '-1' })).to eq(
          settings: {
            index: {
              refresh_interval: '-1',
              number_of_replicas: 4,
            }
          }
        )
      end
    end

    context 'with the settings root key' do
      before do
        stub_index(:geos) do
          settings do
            {
              'settings' => { 'index' => { 'number_of_replicas' => '6'.to_i } },
            }
          end
        end
      end

      specify do
        expect(GeosIndex.settings_hash).to eq(
          settings: { index: { number_of_replicas: 6 } },
        )
      end
    end
  end
end
