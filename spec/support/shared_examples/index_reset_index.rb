# frozen_string_literal: true

RSpec.shared_examples 'index.reset_index' do
  include_context 'with geos index definition'

  let(:index_suffix) { SecureRandom.hex(8) }

  it 'raises an Esse::Transport::ReadonlyClusterError exception when the cluster is readonly' do
    es_client do |client, _conf, cluster|
      cluster.warm_up!
      expect(client).not_to receive(:perform_request)
      cluster.readonly = true
      expect {
        GeosIndex.reset_index(suffix: index_suffix, import: false)
      }.to raise_error(Esse::Transport::ReadonlyClusterError)
    end
  end

  it 'creates a new index, import data and put the alias' do
    es_client do |client, _conf, cluster|
      expect {
        GeosIndex.reset_index(suffix: index_suffix, import: false)
      }.not_to raise_error

      expect(GeosIndex.indices_pointing_to_alias).to eq(["#{GeosIndex.index_name}_#{index_suffix}"])
    end
  end

  it 'does not remove the old index' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: true, suffix: '2021')

      expect {
        GeosIndex.reset_index(suffix: index_suffix, import: false)
      }.not_to raise_error

      expect(GeosIndex.indices_pointing_to_alias).to eq(["#{GeosIndex.index_name}_#{index_suffix}"])
      expect(GeosIndex.index_exist?(suffix: '2021')).to eq(true)
      expect(GeosIndex.index_exist?(suffix: index_suffix)).to eq(true)
    end
  end

  it 'removes index with alias name if it exists' do
    es_client do |client, _conf, cluster|
      client.indices.create(index: GeosIndex.index_name)

      expect {
        GeosIndex.reset_index(suffix: index_suffix, import: false)
      }.not_to raise_error

      expect(GeosIndex.indices_pointing_to_alias).to eq(["#{GeosIndex.index_name}_#{index_suffix}"])
      expect(GeosIndex.index_exist?(suffix: index_suffix)).to eq(true)
    end
  end

  context 'with optimize and import options' do
    it 'optimize index before import documents by disabling refresh_interval and setting number_of_replicas to 0' do
      es_client do |client, _conf, cluster|
        optm_index = Class.new(GeosIndex) do
          self.index_name = 'geos_index_optimized'
          settings do
            {
              index: {
                number_of_replicas: nil,
                refresh_interval: nil,
              }
            }
          end
        end

        # closure
        optm_full_name = optm_index.index_name(suffix: index_suffix)
        during_import_settings = {}
        optm_index.define_singleton_method(:import) do |*|
          during_import_settings.merge! client.indices.get_settings(index: optm_full_name)
        end

        expect {
          optm_index.reset_index(suffix: index_suffix, import: true, optimize: true)
        }.not_to raise_error

        expect(during_import_settings.dig(optm_full_name, 'settings', 'index', 'number_of_replicas')).to eq('0')
        expect(during_import_settings.dig(optm_full_name, 'settings', 'index', 'refresh_interval')).to eq('-1')

        after_import_settings = client.indices.get_settings(index: optm_full_name)
        expect(after_import_settings.dig(optm_full_name, 'settings', 'index', 'number_of_replicas')).to be_one_of(nil, '1')
        expect(after_import_settings.dig(optm_full_name, 'settings', 'index', 'refresh_interval')).to be_one_of(nil, '1s')
      end
    end

    it 'optimize index before reindex by disabling refresh_interval and setting number_of_replicas to 0' do
      es_client do |client, _conf, cluster|
        optm_index = Class.new(GeosIndex) do
          self.index_name = 'geos_index_optimized'
          settings do
            {
              index: {
                number_of_replicas: nil,
                refresh_interval: nil,
              }
            }
          end
        end
        optm_index.create_index(alias: true, suffix: 'v1')

        # closure
        optm_full_name = optm_index.index_name(suffix: index_suffix)
        during_reindex_settings = {}
        optm_index.define_singleton_method(:reindex) do |*|
          during_reindex_settings.merge! client.indices.get_settings(index: optm_full_name)
        end

        expect {
          optm_index.reset_index(suffix: index_suffix, import: false, reindex: true, optimize: true)
        }.not_to raise_error

        expect(during_reindex_settings.dig(optm_full_name, 'settings', 'index', 'number_of_replicas')).to eq('0')
        expect(during_reindex_settings.dig(optm_full_name, 'settings', 'index', 'refresh_interval')).to eq('-1')

        after_reindex_settings = client.indices.get_settings(index: optm_full_name)
        expect(after_reindex_settings.dig(optm_full_name, 'settings', 'index', 'number_of_replicas')).to be_one_of(nil, '1')
        expect(after_reindex_settings.dig(optm_full_name, 'settings', 'index', 'refresh_interval')).to be_one_of(nil, '1s')
      end
    end

    it 'does not optimize index before import documents when optimize is false' do
      es_client do |client, _conf, cluster|
        optm_index = Class.new(GeosIndex) do
          self.index_name = 'geos_index_optimized'
          settings do
            {
              index: {
                number_of_replicas: '2',
                refresh_interval: '30s',
              }
            }
          end
        end

        # closure
        optm_full_name = optm_index.index_name(suffix: index_suffix)
        during_import_settings = {}
        optm_index.define_singleton_method(:import) do |*|
          during_import_settings.merge! client.indices.get_settings(index: optm_full_name)
        end

        expect {
          optm_index.reset_index(suffix: index_suffix, import: true, optimize: false)
        }.not_to raise_error

        expect(during_import_settings.dig(optm_full_name, 'settings', 'index', 'number_of_replicas')).to eq('2')
        expect(during_import_settings.dig(optm_full_name, 'settings', 'index', 'refresh_interval')).to eq('30s')

        after_import_settings = client.indices.get_settings(index: optm_full_name)
        expect(after_import_settings.dig(optm_full_name, 'settings', 'index', 'number_of_replicas')).to eq('2')
        expect(after_import_settings.dig(optm_full_name, 'settings', 'index', 'refresh_interval')).to eq('30s')
      end
    end
  end

  context 'when the old index has data' do
    it 'import data from the old index to the new index' do
      es_client do |client, _conf, cluster|
        GeosIndex.create_index(alias: true, suffix: '2021')
        expect {
          GeosIndex.reset_index(suffix: index_suffix, import: true)
        }.not_to raise_error

        expect(GeosIndex.indices_pointing_to_alias).to eq(["#{GeosIndex.index_name}_#{index_suffix}"])
        expect(GeosIndex.index_exist?(suffix: '2021')).to eq(true)
        expect(GeosIndex.index_exist?(suffix: index_suffix)).to eq(true)
        expect(GeosIndex.count).to be_positive
      end
    end

    it 'forwads the import options to the import method' do
      es_client do |client, _conf, cluster|
        GeosIndex.create_index(alias: true, suffix: '2021')
        expect {
          GeosIndex.reset_index(suffix: index_suffix, import: { refresh: true })
        }.not_to raise_error

        expect(GeosIndex.indices_pointing_to_alias).to eq(["#{GeosIndex.index_name}_#{index_suffix}"])
        expect(GeosIndex.index_exist?(suffix: '2021')).to eq(true)
        expect(GeosIndex.index_exist?(suffix: index_suffix)).to eq(true)
        expect(GeosIndex.count).to be_positive
      end
    end

    it 'create async task to reindex data from the old index and do not update the alias' do |example|
      unless %w[1.x 2.x 5.x].include?(example.metadata[:es_version])
        es_client do |client, _conf, cluster|
          GeosIndex.create_index(alias: true, suffix: '2021')
          GeosIndex.import(refresh: true)

          expect {
            GeosIndex.reset_index(suffix: index_suffix, import: false, reindex: { wait_for_completion: false }, refresh: true)
          }.not_to raise_error

          expect(GeosIndex.indices_pointing_to_alias).to eq(["#{GeosIndex.index_name}_2021"])
          expect(GeosIndex.index_exist?(suffix: '2021')).to eq(true)
          expect(GeosIndex.index_exist?(suffix: index_suffix)).to eq(true)

          count = 0
          (0..3).each do |t|
            GeosIndex.refresh(suffix: index_suffix)
            count = GeosIndex.count(suffix: index_suffix)
            break if count.positive?
            sleep(t) if t.positive?
          end
          expect(count).to be_positive
        end
      end
    end

    it 'reindex data from the old index to the new index by awaiting for completion' do |example|
      unless %w[1.x 2.x 5.x].include?(example.metadata[:es_version])
        es_client do |client, _conf, cluster|
          GeosIndex.create_index(alias: true, suffix: '2021')
          GeosIndex.import(refresh: true)

          expect {
            GeosIndex.reset_index(suffix: index_suffix, import: false, reindex: { wait_for_completion: true, poll_interval: 0.2 }, refresh: true)
          }.not_to raise_error

          expect(GeosIndex.indices_pointing_to_alias).to eq(["#{GeosIndex.index_name}_#{index_suffix}"])
          expect(GeosIndex.index_exist?(suffix: '2021')).to eq(true)
          expect(GeosIndex.index_exist?(suffix: index_suffix)).to eq(true)
          expect(GeosIndex.count).to be_positive
        end
      end
    end
  end
end
