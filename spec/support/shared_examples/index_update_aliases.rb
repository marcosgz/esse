# frozen_string_literal: true

RSpec.shared_examples 'index.update_aliases' do
  include_context 'with geos index definition'

  let(:index_suffix) { SecureRandom.hex(8) }

  it 'raises an Esse::Transport::ServerError exception when api throws an error' do
    es_client do |client, _conf, cluster|
      expect {
        GeosIndex.update_aliases(suffix: index_suffix)
      }.to raise_error(Esse::Transport::ServerError)
    end
  end

  it 'adds the alias to the index' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: false, suffix: index_suffix)

      expect {
        GeosIndex.update_aliases(suffix: index_suffix)
      }.to change { GeosIndex.indices_pointing_to_alias }.from([]).to(["#{GeosIndex.index_name}_#{index_suffix}"])
    end
  end

  it 'replace the alias to the index' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: true, suffix: index_suffix)
      GeosIndex.create_index(alias: false, suffix: '2023')

      expect {
        GeosIndex.update_aliases(suffix: '2023')
      }.to change { GeosIndex.indices_pointing_to_alias }.from(["#{GeosIndex.index_name}_#{index_suffix}"]).to(["#{GeosIndex.index_name}_2023"])
    end
  end
end
