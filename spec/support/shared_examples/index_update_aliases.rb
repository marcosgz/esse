# frozen_string_literal: true

RSpec.shared_examples 'index.update_aliases' do
  include_context 'with geos index definition'

  let(:index_suffix) { SecureRandom.hex(8) }

  it 'raises an Esse::Transport::ReadonlyClusterError exception when the cluster is readonly' do
    es_client do |client, _conf, cluster|
      expect(client).not_to receive(:perform_request)
      cluster.readonly = true
      expect {
        GeosIndex.update_aliases(suffix: index_suffix)
      }.to raise_error(Esse::Transport::ReadonlyClusterError)
    end
  end

  it 'raises an Esse::Transport::ServerError exception when api throws an error' do
    es_client do |client, _conf, cluster|
      expect {
        GeosIndex.update_aliases(suffix: index_suffix)
      }.to raise_error(Esse::Transport::ServerError)
    end
  end

  it 'adds a signle alias to the index' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: false, suffix: index_suffix)

      expect {
        GeosIndex.update_aliases(suffix: index_suffix)
      }.to change { GeosIndex.indices_pointing_to_alias }.from([]).to(["#{GeosIndex.index_name}_#{index_suffix}"])
    end
  end

  it 'adds multiple aliases to the index' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: false, suffix: '2023')
      GeosIndex.create_index(alias: false, suffix: '2024')

      expect {
        GeosIndex.update_aliases(suffix: %w[2023 2024])
      }.to change { GeosIndex.indices_pointing_to_alias }.from([]).to(
        an_instance_of(Array).and(
          include("#{GeosIndex.index_name}_2023", "#{GeosIndex.index_name}_2024"),
        )
      )
    end
  end

  it 'replace one existing alias by the new one' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: true, suffix: index_suffix)
      GeosIndex.create_index(alias: false, suffix: '2023')

      expect {
        GeosIndex.update_aliases(suffix: '2023')
      }.to change { GeosIndex.indices_pointing_to_alias }.from(["#{GeosIndex.index_name}_#{index_suffix}"]).to(["#{GeosIndex.index_name}_2023"])
    end
  end

  it 'replaces multiple existing aliases by the new one' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: false, suffix: '2023')
      GeosIndex.create_index(alias: false, suffix: '2024')
      GeosIndex.create_index(alias: false, suffix: '2025')

      GeosIndex.update_aliases(suffix: %w[2023 2024])

      expect {
        GeosIndex.update_aliases(suffix: '2025')
      }.to change { GeosIndex.indices_pointing_to_alias }.from(
        an_instance_of(Array).and(
          include("#{GeosIndex.index_name}_2023", "#{GeosIndex.index_name}_2024"),
        )
      ).to(["#{GeosIndex.index_name}_2025"])
    end
  end

  it 'replaces one existing alias by multiple new ones' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: true, suffix: index_suffix)
      GeosIndex.create_index(alias: false, suffix: '2023')
      GeosIndex.create_index(alias: false, suffix: '2024')

      expect {
        GeosIndex.update_aliases(suffix: %w[2023 2024])
      }.to change { GeosIndex.indices_pointing_to_alias }.from(["#{GeosIndex.index_name}_#{index_suffix}"]).to(
        an_instance_of(Array).and(
          include("#{GeosIndex.index_name}_2023", "#{GeosIndex.index_name}_2024"),
        )
      )
    end
  end
end
